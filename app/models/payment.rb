# == Schema Information
#
# Table name: payments
#
#  id                 :integer          not null, primary key
#  order_id           :integer          not null
#  amount             :decimal(8, 2)    not null
#  terminal           :string
#  transaction_type   :string
#  card_country       :string
#  response_code      :string
#  authorization_code :string
#  currency           :string
#  merchant_code      :string
#  success            :boolean
#  payment_type       :string
#  paid_at            :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  last4              :string
#

class Payment < ActiveRecord::Base
  default_scope { order(created_at: :desc) }

  # Associations
  belongs_to :order

  # Validations
  validates :order, :amount, presence: true

  DIRECT_TYPES = %w( wirecard paypal paypal_nvp braintree ).freeze
end