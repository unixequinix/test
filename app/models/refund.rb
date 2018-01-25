class Refund < ApplicationRecord
  include Eventable
  include Creditable

  attr_accessor :iban, :bsb

  belongs_to :event, counter_cache: true
  belongs_to :customer

  validates :gateway, presence: true
  validate :extra_params_fields

  validate :correct_iban_and_swift, if: :iban

  validate_associations

  scope :completed, -> { where status: "completed" }

  def complete!(_refund_data = {}.to_json)
    return false if completed?
    update!(status: "completed")

    atts = { items_amount: price_money, payment_gateway: gateway, payment_method: "online", price: -total_money }
    MoneyTransaction.write!(event, "online_refund", :portal, customer, customer, atts)

    atts = { payments: { event.credit.id => { amount: -amount, final_balance: customer.credits } }, customer: customer }
    CreditTransaction.write!(event, "refund", :portal, customer, customer, atts)

    OrderMailer.completed_refund(self).deliver_later
  end

  def prepare_for_bank_account(atts)
    return unless gateway.eql?("bank_account")
    self.fields = atts[:fields].to_h.each { |key, val| atts[:fields][key] = val.gsub(/\s+/, '') }
    self.iban = true if event.iban?
    self.bsb = true if event.bsb?
  end

  # TODO: Change this to enum
  def completed?
    status.eql?("completed")
  end

  def price_money
    amount * event.credit.value
  end

  def correct_iban_and_swift
    validator = IBANTools::IBAN
    msg = validator.new(fields[:iban]).validation_errors.map(&:to_s).map(&:humanize).to_sentence
    errors.add(:iban, msg) unless validator.valid?(fields[:iban])
    validator = ISO::SWIFT.new(fields[:swift])
    msg = validator.errors.map(&:to_s).map(&:humanize).to_sentence
    errors.add(:swift, msg) unless validator.valid?
  end

  def extra_params_fields
    event.refund_fields.each do |field|
      errors.add(:fields, "Field #{field} not found") if fields[field.to_s].blank?
    end
  end
end
