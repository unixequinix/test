module Creditable
  extend ActiveSupport::Concern

  included do
    validates :fee, :amount, numericality: { greater_than_or_equal_to: 0 }, presence: true
  end

  def number
    id.to_s.rjust(7, "0")
  end

  def total_formatted
    format("%.2f", total.to_f)
  end

  def total
    amount.to_f + fee.to_f
  end

  def fee_money
    fee.to_f * event.credit.value
  end

  def total_money
    total.to_f * event.credit.value
  end

  private

  def associations_in_event
    self.class.assoc.each do |assoc|
      obj = assoc.gsub("_id", "").classify.constantize.find_by(id: method(assoc).call)
      errors.add(assoc, "cannot belong to a different event") if obj && obj&.event != event
    end
  end
end
