class Customer < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :omniauthable, :trackable, :confirmable,
         authentication_keys: %i[email event_id],
         reset_password_keys: %i[email event_id],
         reset_password_within: 1.day,
         sign_in_after_reset_password: true,
         omniauth_providers: %i[facebook google_oauth2]

  belongs_to :event

  has_one :active_gtag, -> { where(active: true) }, class_name: "Gtag", inverse_of: :customer
  has_many :orders, dependent: :restrict_with_error
  has_many :refunds, dependent: :restrict_with_error
  has_many :tickets, dependent: :nullify
  has_many :gtags, dependent: :nullify
  has_many :transactions, dependent: :restrict_with_error
  has_many :transactions_as_operator, class_name: "Transaction", foreign_key: "operator_id", dependent: :restrict_with_error, inverse_of: :operator
  has_many :pokes, dependent: :restrict_with_error
  has_many :pokes_as_operator, class_name: "Poke", foreign_key: "operator_id", dependent: :restrict_with_error, inverse_of: :operator

  has_attached_file(:avatar, styles: { thumb: '50x50#', medium: '200x200#', big: '500x500#' }, default_url: ':default_user_avatar_url')
  validates_attachment_content_type :avatar, content_type: %r{\Aimage/.*\Z}

  ransacker :full_name do |parent|
    Arel::Nodes::NamedFunction.new('CONCAT_WS', [Arel::Nodes.build_quoted(' '), parent.table[:first_name], parent.table[:last_name]])
  end

  with_options unless: :anonymous? do |reg|
    reg.validates :email, format: { with: RFC822::EMAIL }, allow_blank: false
    reg.validates :email, uniqueness: { scope: [:event_id] }, allow_blank: false
    reg.validates :email, :first_name, :last_name, :encrypted_password, presence: true
    reg.validates :agreed_on_registration, acceptance: { accept: true }
    reg.validates :agreed_event_condition, acceptance: { accept: true }, if: (-> { event&.agreed_event_condition? })

    reg.validates :password, presence: true,
                             confirmation: true,
                             length: { within: Devise.password_length },
                             format: { with: /\A(?=.*\d)(?=.*[a-z])|(?=.*\d)(?=.*[a-z])\z/, message: 'must include 1 lowercase letter and 1 digit' },
                             unless: (-> { password.nil? })
  end

  validates :phone, presence: true, if: (-> { custom_validation("phone") })
  validates :birthdate, presence: true, if: (-> { custom_validation("birthdate") })
  validates :phone, presence: true, if: (-> { custom_validation("phone") })
  validates :postcode, presence: true, if: (-> { custom_validation("address") })
  validates :address, presence: true, if: (-> { custom_validation("address") })
  validates :city, presence: true, if: (-> { custom_validation("address") })
  validates :country, presence: true, if: (-> { custom_validation("address") })
  validates :gender, presence: true, if: (-> { custom_validation("gender") })

  attr_accessor :confirmation # TODO[fmoya] Ana's project hack to send email on user creation
  alias customer itself

  before_save :set_gdpr_acceptance

  scope :anonymous, -> { where(anonymous: true) }
  scope :registered, -> { where(anonymous: false) }
  scope :operator, -> { where(operator: true) }
  scope :with_operator, ->(operators) { operators.present? ? where(operator: operators) : all }

  def self.policy_class
    AdmissionPolicy
  end

  def self.claim(event, customer, anon_customers)
    anon_customers = [anon_customers].flatten.compact

    return customer if customer.blank? || anon_customers.map(&:id).uniq.all? { |id| id == customer.id }

    message = "PROFILE FRAUD: customers #{anon_customers.map(&:id).to_sentence} are registered when trying to claim"
    Alert.propagate(event, customer, message) && return if anon_customers.map(&:registered?).any?

    anon_customers.each do |anon_customer|
      anon_customer.transactions.update_all(customer_id: customer.id)
      anon_customer.pokes.update_all(customer_id: customer.id)
      anon_customer.gtags.update_all(customer_id: customer.id)
      anon_customer.tickets.update_all(customer_id: customer.id)
      anon_customer.reload.destroy!
    end

    customer
  end

  def valid_balance?
    positive = (credits && virtual_credits) >= 0
    active_gtag.present? ? (active_gtag.valid_balance? && positive) : positive
  end

  def registered?
    !anonymous?
  end

  def name
    result = "#{first_name} #{last_name}"
    result = "Anonymous customer" if anonymous?
    result = "Anonymous operator" if anonymous? && operator?
    result
  end

  def full_email
    anonymous? ? "Anonymous email" : email
  end

  def credits
    credential_total = credential_catalog_items.sum(&:credits)
    order_total = orders.completed.includes(:order_items).reject(&:redeemed?).sum(&:credits)
    refund_total = refunds.completed.sum(&:credit_total)
    gtag_credits = active_gtag&.final_balance.to_f

    credential_total + order_total - refund_total + gtag_credits
  end

  def virtual_credits
    credential_total = credential_catalog_items.sum(&:virtual_credits)
    order_total = orders.completed.includes(:order_items).reject(&:redeemed?).sum(&:virtual_credits)
    gtag_credits = active_gtag&.final_virtual_balance.to_f

    credential_total + order_total + gtag_credits
  end

  def tokens(tkns = nil)
    tokens = [tkns.presence || event.tokens].flatten
    credential_total = credential_catalog_items.sum { |ci| ci.value if tokens.include?(ci) }.to_f
    order_total = tokens.map { |_token| orders.completed.includes(:order_items).reject(&:redeemed?).sum(&:tokens) }.sum.to_f
    gtag_credits = tokens.map { |token| active_gtag&.final_tokens_balance.try(:[], token&.id&.to_s) }.compact.sum.to_f
    credential_total + order_total + gtag_credits
  end

  def credential_catalog_items
    event.ticket_types.where.not(catalog_item: nil).where(id: tickets.unredeemed.pluck(:ticket_type_id) + gtags.unredeemed.pluck(:ticket_type_id)).map(&:catalog_item)
  end

  def money
    credits * event.credit.value
  end

  def virtual_money
    virtual_credits * event.credit.value
  end

  def credentials
    gtags + tickets
  end

  def active_credentials
    [active_gtag, tickets.where(banned: false)].flatten.compact
  end

  def order_items
    OrderItem.where(order: orders)
  end

  def build_order(items, atts = {})
    order = orders.new(atts.merge(event: event, status: "in_progress"))

    credit_info = items.map do |arr|
      arr.unshift(event.credit.id) if arr.size.eql?(1)
      item_id, amount = arr
      [0, 0] if amount.to_f.zero?

      item = event.catalog_items.find(item_id)
      order.order_items.build(catalog_item: item, amount: amount.to_f)
      [item.credits * amount.to_f, item.virtual_credits * amount.to_f, item.tokens * amount.to_f]
    end

    order.credits = credit_info.map(&:first).sum
    order.virtual_credits = credit_info.map(&:second).sum
    order.tokens = credit_info.map(&:last).sum

    order.set_counters
  end

  def can_purchase_item?(catalog_item)
    active_credentials.map { |credential| credential.ticket_type&.catalog_item }.compact.include?(catalog_item)
  end

  def infinite_accesses_purchased
    catalog_items = order_items.pluck(:catalog_item_id)
    accesses = event.accesses.where(id: catalog_items).infinite.pluck(:id)
    packs = event.packs.joins(:catalog_items).where(id: catalog_items, catalog_items: { type: "Access" }).select { |pack| pack.catalog_items.accesses.infinite.any? }.map(&:id)

    accesses + packs
  end

  def self.from_omniauth(auth, event)
    token = Devise.friendly_token[0, 20]
    first_name = auth.info&.first_name || auth.info.name.split(" ").first
    last_name = auth.info&.last_name || auth.info.name.split(" ").second

    customer = find_by(provider: auth.provider, uid: auth.uid, event: event)
    customer ||= event.customers.new(provider: auth.provider, uid: auth.uid, email: auth.info.email, first_name: first_name, last_name: last_name, password: token, password_confirmation: token, agreed_on_registration: true)
    customer.anonymous = false
    customer.skip_confirmation!
    customer.save
    customer
  end

  def custom_validation(field)
    event&.method("#{field}_mandatory?")&.call && !reset_password_token_changed? &&
      (!encrypted_password_changed? || new_record?) && !anonymous?
  end

  def validate_gtags
    active_gtag = customer.gtags.order(updated_at: :desc).first
    active_gtag&.update(active: true)
    customer.gtags.where.not(id: active_gtag.id).update_all(active: false) unless active_gtag.nil?
  end

  private

  def set_gdpr_acceptance
    self.gdpr_acceptance_at = Time.current if gdpr_acceptance
  end

  def generate_token(column)
    loop do
      self[column] = SecureRandom.urlsafe_base64
      break unless Customer.exists?(column => self[column])
    end
  end
end
