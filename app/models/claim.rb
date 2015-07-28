# == Schema Information
#
# Table name: claims
#
#  id           :integer          not null, primary key
#  customer_id  :integer          not null
#  number       :string           not null
#  aasm_state   :string           not null
#  completed_at :datetime
#  total        :decimal(8, 2)    not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  gtag_id      :integer
#  service_type :string
#  fee          :decimal(8, 2)    default(0.0)
#  minimum      :decimal(8, 2)    default(0.0)
#

class Claim < ActiveRecord::Base
  default_scope { order(created_at: :desc) }

  #Service Types
  BANK_ACCOUNT = 'bank_account'
  EASY_PAYMENT_GATEWAY = 'epg'

  REFUND_SERVICES = [BANK_ACCOUNT, EASY_PAYMENT_GATEWAY]


  # Associations
  belongs_to :customer
  has_one :refund
  has_many :claim_parameters
  belongs_to :gtag

  # Validations
  validates :customer, :gtag, :service_type, :number, :total, :aasm_state, presence: true

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
    time_hex = Time.now.strftime('%H%M%L').to_i.to_s(16)
    day = Date.today.strftime('%y%m%d')
    self.number = "#{day}#{time_hex}"
  end

  # def generate_claim_number!
  #   gtag_uid = self.gtag.tag_uid.to_i(16)
  #   gtag_serial_number = self.gtag.tag_serial_number.to_i(16)
  #   customer = self.customer.id
  #   self.number = "#{gtag_uid}#{customer}#{gtag_serial_number}"
  # end

  def total_after_fee
    total - fee
  end

  def enough_credits?
    total - fee >= minimum
  end

  private

  def complete_claim
    self.update(completed_at: Time.now())
  end

  # TODO Improve this download
  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      claim_columns = []
      claim_columns << 'name'
      claim_columns << 'surname'
      claim_columns << 'email'
      claim_columns << 'UID'
      claim_columns << 'Serial Number'
      claim_columns << 'IBAN'
      claim_columns << 'SWIFT/BIC'
      claim_columns << 'amount'
      csv << claim_columns
      all.each do |claim|
        attributes = []
        attributes[0] = claim.customer.nil? ? '' : claim.customer.name
        attributes[1] = claim.customer.nil? ? '' : claim.customer.surname
        attributes[2] = claim.customer.nil? ? '' : claim.customer.email
        attributes[3] = claim.gtag.nil? ? '' : claim.gtag.tag_uid
        attributes[4] = claim.gtag.nil? ? '' : claim.gtag.tag_serial_number
        attributes[5] = claim.claim_parameters.nil? ? '' : claim.claim_parameters.find_by(parameter_id: Parameter.find_by(category: 'claim', group: 'bank_account', name: 'iban')).value
        attributes[6] = claim.claim_parameters.nil? ? '' : claim.claim_parameters.find_by(parameter_id: Parameter.find_by(category: 'claim', group: 'bank_account', name: 'swift')).value
        attributes[7] = claim.gtag.gtag_credit_log.nil? ? '' : claim.gtag.gtag_credit_log.amount
        csv << attributes
      end
    end
  end
end
