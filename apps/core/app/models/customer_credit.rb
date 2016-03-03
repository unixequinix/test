# == Schema Information
#
# Table name: customer_credits
#
#  id                        :integer          not null, primary key
#  customer_event_profile_id :integer          not null
#  transaction_source        :string           not null
#  payment_method            :string           not null
#  amount                    :decimal(, )      not null
#  refundable_amount         :decimal(, )      not null
#  final_balance             :decimal(, )      not null
#  final_refundable_balance  :decimal(, )      not null
#  credit_value              :decimal(, )      not null
#  deleted_at                :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

class CustomerCredit < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :customer_event_profile

  validates_presence_of :payment_method, :transaction_source, :customer_event_profile
  validates_numericality_of :amount, :refundable_amount, :credit_value
  validates_numericality_of :final_balance, :final_refundable_balance, greater_than_or_equal_to: 0

  TICKET_ASSIGNMENT  = "ticket_assignment"
  TICKET_UNASSIGNMENT  = "ticket_unassignment"
  CREDITS_PURCHASE  = "credits_purchase"

  # Type of the invoices
  TRANSACTION_TYPES = [TICKET_ASSIGNMENT, TICKET_UNASSIGNMENT, CREDITS_PURCHASE]
end
