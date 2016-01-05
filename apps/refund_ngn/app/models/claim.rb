# == Schema Information
#
# Table name: claims
#
#  id                        :integer          not null, primary key
#  number                    :string           not null
#  aasm_state                :string           not null
#  completed_at              :datetime
#  total                     :decimal(8, 2)    not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  gtag_id                   :integer
#  service_type              :string
#  fee                       :decimal(8, 2)    default(0.0)
#  minimum                   :decimal(8, 2)    default(0.0)
#  customer_event_profile_id :integer
#

class Claim < ActiveRecord::Base
  default_scope { order(created_at: :desc) }

  # Service Types
  BANK_ACCOUNT = "bank_account"
  EASY_PAYMENT_GATEWAY = "epg"
  TIPALTI = "tipalti"

  REFUND_SERVICES = [BANK_ACCOUNT, EASY_PAYMENT_GATEWAY, TIPALTI]

  # Associations
  belongs_to :customer_event_profile
  has_one :refund
  has_many :claim_parameters
  belongs_to :gtag

  # Validations
  validates :customer_event_profile, :gtag, :service_type, :number, :total,
            :aasm_state, presence: true

  # Scopes
  scope :query_for_csv, lambda  { |aasm_state, event|
    joins(:customer_event_profile, :gtag, :refund,
          customer_event_profile: :customer)
      .includes(:claim_parameters, claim_parameters: :parameter)
      .where(aasm_state: aasm_state)
      .where(customer_event_profiles: { event_id: event.id })
      .select("claims.id, customers.name, customers.surname, customers.email,
            gtags.tag_uid, gtags.tag_serial_number, refunds.amount,
            claims.service_type").order(:id)
  }

  # State machine
  include AASM

  aasm do
    state :started, initial: true
    state :in_progress
    state :completed, enter: :complete_claim
    state :cancelled

    event :start_claim do
      transitions from: [:started, :in_progress], to: :in_progress
    end

    event :complete do
      transitions from: :in_progress, to: :completed
    end

    event :cancel do
      transitions from: :completed, to: :cancelled
    end
  end

  def generate_claim_number!
    time_hex = Time.now.strftime("%H%M%L").to_i.to_s(16)
    day = Date.today.strftime("%y%m%d")
    self.number = "#{day}#{time_hex}"
  end

  def self.selected_data(aasm_state, event)
    claims = query_for_csv(aasm_state, event)
    headers = []
    extra_columns = {}
    claims.each_with_index do |claim, index|
      extra_columns[index + 1] = claim.claim_parameters.reduce({}) do |acum, claim_parameter|
        headers |= [claim_parameter.parameter.name]
        acum[claim_parameter.parameter.name] = claim_parameter.value
        acum
      end
    end
    [claims, headers, extra_columns]
  end

  private

  def complete_claim
    update(completed_at: Time.now)
  end
end
