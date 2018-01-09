class Transaction < ApplicationRecord
  include Alertable

  belongs_to :event
  belongs_to :station, optional: true
  belongs_to :operator, class_name: "Customer", optional: true, inverse_of: :transactions_as_operator
  belongs_to :operator_gtag, class_name: "Gtag", optional: true, inverse_of: :transactions_as_operator
  belongs_to :customer, optional: true
  belongs_to :gtag, optional: true
  belongs_to :catalog_item, optional: true
  belongs_to :ticket, optional: true
  belongs_to :order, optional: true
  belongs_to :order_item, optional: true

  has_many :pokes, dependent: :restrict_with_error

  scope :credit, -> { where(type: "CreditTransaction") }
  scope :credential, -> { where(type: "CredentialTransaction") }
  scope :access, -> { where(type: "AccessTransaction") }
  scope :money, -> { where(type: "MoneyTransaction") }
  scope :ban, -> { where(type: "BanTransaction") }
  scope :orders, -> { where(type: "OrderTransaction") }
  scope :device, -> { where(type: "DeviceTransaction") }
  scope :onsite, -> { where(transaction_origin: ORIGINS[:device]) }
  scope :online, -> { where.not(transaction_origin: ORIGINS[:device]) }
  scope :api, -> { where(transaction_origin: [ORIGINS[:api]]) }

  scope :with_event, ->(event) { where(event: event) }
  scope :with_customer_tag, ->(tag_uid) { where(customer_tag_uid: tag_uid) }
  scope :status_ok, -> { where(status_code: 0) }
  scope :status_not_ok, -> { where.not(status_code: 0) }
  scope :origin, ->(origin) { where(transaction_origin: Transaction::ORIGINS[origin]) }
  scope :payments_with_credit, ->(credit) { where("payments ? '#{credit.id}'") }

  ORIGINS = { portal: "customer_portal", device: "onsite", admin: "admin_panel", api: "api" }.freeze
  TYPES = %w[access credential credit money order operator user_engagement user_flag].freeze

  validates :transaction_origin, :action, :device_created_at, presence: true

  def self.write!(event, action, origin, customer, operator, atts) # rubocop:disable Metrics/ParameterLists
    Time.zone = event.timezone
    now = Time.zone.now.to_formatted_s(:transactions)
    counter = customer&.transactions&.where(transaction_origin: Transaction::ORIGINS[origin])&.maximum(:counter).to_i + 1
    attributes = { event: event,
                   action: action,
                   counter: counter,
                   customer: customer,
                   status_code: 0,
                   status_message: "OK",
                   transaction_origin: Transaction::ORIGINS[origin],
                   station: event.portal_station,
                   device_created_at: now,
                   device_created_at_fixed: now,
                   operator_tag_uid: operator&.email }.merge(atts)

    transaction = create!(attributes)
    Pokes::Base.execute_descendants(transaction)
    transaction
  end

  def name
    action.humanize
  end

  def category
    type.gsub("Transaction", "").underscore
  end

  def description
    "#{category.humanize}: #{action.humanize}"
  end

  def status_ok?
    status_code.zero?
  end

  def status_not_ok?
    !status_code.zero?
  end

  def self.mandatory_fields
    %w[action customer_tag_uid operator_tag_uid device_uid device_db_index device_created_at status_code status_message]
  end
end
