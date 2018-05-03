class Event < ApplicationRecord
  extend FriendlyId

  has_many :device_registrations, dependent: :destroy
  has_many :devices, through: :device_registrations, dependent: :destroy
  has_many :transactions, dependent: :restrict_with_error
  has_many :tickets, dependent: :destroy
  has_many :catalog_items, dependent: :destroy
  has_many :ticket_types, dependent: :destroy
  has_many :gtags, dependent: :destroy
  has_many :stations, dependent: :destroy
  has_many :device_transactions, dependent: :destroy
  has_many :user_flags, dependent: :destroy
  has_many :accesses, dependent: :destroy
  has_many :operator_permissions, dependent: :destroy
  has_many :packs, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :refunds, dependent: :destroy
  has_many :event_registrations, dependent: :destroy
  has_many :users, through: :event_registrations, dependent: :destroy
  has_many :alerts, dependent: :destroy
  has_many :device_caches, dependent: :destroy
  has_many :pokes, dependent: :restrict_with_error
  has_many :api_metrics, dependent: :destroy
  has_many :ticketing_integrations, dependent: :destroy
  has_many :eventbrite_ticketing_integrations, class_name: "TicketingIntegrationEventbrite", dependent: :destroy, inverse_of: :event
  has_many :universe_ticketing_integrations, class_name: "TicketingIntegrationUniverse", dependent: :destroy, inverse_of: :event
  has_many :palco4_ticketing_integrations, class_name: "TicketingIntegrationPalco4", dependent: :destroy, inverse_of: :event

  has_one :credit, dependent: :destroy
  has_one :virtual_credit, dependent: :destroy

  belongs_to :event_serie, optional: true

  scope :with_state, ->(state) { where state: state }
  scope :live, -> { where(state: 'launched', open_devices_api: true) }

  friendly_id :name, use: :slugged

  has_paper_trail on: :update

  enum state: { created: 1, launched: 2, closed: 3 }
  enum bank_format: { nothing: 0, iban: 1, bsb: 2 }
  enum gtag_format: { both: 0, wristband: 1, card: 2 }

  USER_FLAGS = %w[alcohol_forbidden banned initial_topup].freeze
  DEFAULT_STATIONS = { cs_topup_refund: "CS Topup/Refund", cs_accreditation: "CS Accreditation", hospitality_top_up: "Glownet Food", touchpoint: "Touchpoint", operator_permissions: "Operator Permissions", gtag_recycler: "Gtag Recycler", gtag_replacement: "Gtag Replacement", yellow_card: "Yellow Card" }.freeze

  S3_FOLDER = "#{Rails.application.secrets.s3_images_folder}/event/:id/".freeze

  has_attached_file(:logo, path: "#{S3_FOLDER}logos/:style/:filename", url: "#{S3_FOLDER}logos/:style/:basename.:extension", styles: { email: "x120", panel: "200x" }, default_url: ':default_event_image_url')
  has_attached_file(:background, path: "#{S3_FOLDER}backgrounds/:filename", url: "#{S3_FOLDER}backgrounds/:basename.:extension", default_url: ':default_event_background_url')

  before_create :generate_tokens
  before_save :round_fees

  validates :name, :app_version, :support_email, :timezone, :start_date, :end_date, :currency, presence: true
  validates :sync_time_gtags, :sync_time_tickets, :transaction_buffer, :days_to_keep_backup, :sync_time_customers, :sync_time_server_date, :sync_time_basic_download, :sync_time_event_parameters, numericality: { greater_than: 0 }
  validates :onsite_initial_topup_fee, :online_initial_topup_fee, :gtag_deposit_fee, :every_topup_fee, :refund_fee, :refund_minimum, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :maximum_gtag_balance, :credit_step, numericality: { greater_than: 0 }
  validates :name, uniqueness: true
  validates :support_email, format: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates :gtag_key, format: { with: /\A[a-zA-Z0-9]+\z/, message: I18n.t("alerts.only_letters_and_numbers") }, length: { is: 32 }, unless: -> { :new_record? }
  validate :end_date_after_start_date
  validate :refunds_start_after_end_date
  validate :refunds_end_after_refunds_start
  validates_attachment_content_type :logo, content_type: %r{\Aimage/.*\Z}
  validates_attachment_content_type :background, content_type: %r{\Aimage/.*\Z}
  validate :currency_symbol

  def credits
    [credit, virtual_credit].compact
  end

  def cash_income
    orders.completed.includes(order_items: :catalog_item).where.not(catalog_items: { type: 'VirtualCredit' }).pluck(:money_base, :money_fee).flatten.sum +
      credential_income +
      pokes.where(action: %w[purchase topup]).where.not(payment_method: %w[none other]).is_ok.sum(:monetary_total_price)
  end

  def cash_outcome
    (onsite_sales.sum(:credit_amount).to_f.abs * credit.value) +
      (refunds.completed.sum(:credit_base).abs * credit.value) +
      pokes.where(action: 'refund').is_ok.sum(:monetary_total_price).abs
  end

  def credential_income
    tickets.where.not(customer_id: nil).joins(:ticket_type).select("tickets.*, (ticket_types.money_base + ticket_types.money_fee) AS money").sum(&:money)
  end

  def onsite_sales
    pokes.where(action: 'sale', credit: credit).is_ok.includes(:station)
  end

  def onsite_refunds
    pokes.where(action: 'refund').is_ok
  end

  def onsite_topups
    pokes.where(action: 'topup').where.not(payment_method: %w[none other]).is_ok
  end

  def topup_order_items
    OrderItem.where(order: orders.completed, catalog_item: credit)
  end

  def total_spending_power
    onsite_spending_power + online_spending_power
  end

  def onsite_spending_power
    pokes.where(credit: credit).is_ok.sum(:credit_amount) * credit.value
  end

  def online_spending_power
    ticket_type_credits = ticket_types.includes(:catalog_item).where.not(catalog_item_id: nil).map { |tt| [tt.id, tt.catalog_item.credits] }.to_h
    credential_sp = tickets.with_customer.unredeemed.pluck(:ticket_type_id).map { |tt_id| ticket_type_credits[tt_id].to_f }.sum + gtags.with_customer.unredeemed.pluck(:ticket_type_id).map { |tt_id| ticket_type_credits[tt_id].to_f }.sum
    order_sp = OrderItem.where(order: orders.completed, redeemed: false, catalog_item: credit).sum(:amount)
    refund_sp = refunds.completed.sum("credit_base + credit_fee")

    (credential_sp + order_sp - refund_sp) * credit.value
  end

  def message
    "Data shown here is provisional until the event is closed, all device are synced & locked, and the event data is fully wrapped." if launched?
  end

  def currency_symbol
    Money::Currency.find(currency.downcase.to_sym).symbol if currency.present?
  end

  def formatted_start_date
    start_date.to_formatted_s(:best_in_place)
  end

  def formatted_end_date
    end_date.to_formatted_s(:best_in_place)
  end

  def valid_app_version?(device_version)
    return true if app_version.eql?("all")
    return false unless device_version
    Gem::Version.new(app_version) <= Gem::Version.new(device_version.delete("^0-9\."))
  end

  def portal_station
    stations.find_by(category: "customer_portal")
  end

  def initial_setup!
    create_credit!(value: 1, name: "CRD")
    create_virtual_credit!(value: 1, name: "Virtual")
    USER_FLAGS.each { |name| user_flags.create!(name: name) }
    DEFAULT_STATIONS.each { |category, name| stations.create! category: category, name: name }
    station = stations.create! name: "Customer Portal", category: "customer_portal"
    station.station_catalog_items.create(catalog_item: credit, price: 1)
  end

  def start_end_dates_range
    (start_date.to_date.to_datetime..end_date.to_datetime).map(&:to_date)
  end

  private

  def should_generate_new_friendly_id?
    false || super
  end

  def round_fees
    self.onsite_initial_topup_fee = onsite_initial_topup_fee.to_f.round(2) if onsite_initial_topup_fee.present?
    self.online_initial_topup_fee = online_initial_topup_fee.to_f.round(2) if online_initial_topup_fee.present?
    self.gtag_deposit_fee = gtag_deposit_fee.to_f.round(2) if gtag_deposit_fee.present?
    self.every_topup_fee = every_topup_fee.to_f.round(2) if every_topup_fee.present?
    self.refund_fee = refund_fee.to_f.round(2) if refund_fee.present?
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank? || end_date >= start_date
    errors.add(:end_date, "must be after start date")
  end

  def refunds_start_after_end_date
    return if end_date.blank? || refunds_start_date.blank? || refunds_start_date >= end_date
    errors.add(:refunds_start_date, "must be after end date")
  end

  def refunds_end_after_refunds_start
    return if refunds_end_date.blank? || refunds_start_date.blank? || refunds_end_date >= refunds_start_date
    errors.add(:refunds_end_date, "must be after refunds start date")
  end

  def generate_tokens
    self.gtag_key = SecureRandom.hex(16).upcase
  end

  def api_response(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["authorization"] = "Bearer #{@token}"
    @response = JSON.parse(http.request(request).body)
  end
end
