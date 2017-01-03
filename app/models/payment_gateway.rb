# == Schema Information
#
# Table name: payment_gateways
#
#  data                :jsonb            not null
#  gateway             :string
#  refund              :boolean
#  refund_field_a_name :string           default("iban")
#  refund_field_b_name :string           default("swift")
#  topup               :boolean
#
# Indexes
#
#  index_payment_gateways_on_event_id  (event_id)
#
# Foreign Keys
#
#  fk_rails_9c9a24f555  (event_id => events.id)
#

class PaymentGateway < ActiveRecord::Base
  belongs_to :event

  GATEWAYS = YAML.load_file(Rails.root.join('config', 'glownet', 'payment_gateways.yml'))
                 .reject! { |k, _v| k.eql?("commons") }

  validates :gateway, uniqueness: { scope: :event_id }

  scope :topup, -> { where(topup: true) }
  scope :refund, -> { where(refund: true) }
  scope :paypal, -> { find_by(gateway: "paypal") }
  scope :redsys, -> { find_by(gateway: "redsys") }
  scope :stripe, -> { find_by(gateway: "stripe") }
  scope :wirecard, -> { find_by(gateway: "wirecard") }
  scope :bank_account, -> { find_by(gateway: "bank_account") }
end
