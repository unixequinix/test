# == Schema Information
#
# Table name: gtags
#
#  activation_counter       :integer          default(1)
#  active                   :boolean          default(TRUE)
#  banned                   :boolean          default(FALSE)
#  credits                  :decimal(8, 2)
#  final_balance            :decimal(8, 2)
#  final_refundable_balance :decimal(8, 2)
#  format                   :string           default("wristband")
#  loyalty                  :boolean          default(FALSE)
#  refundable_credits       :decimal(8, 2)
#
# Indexes
#
#  index_gtags_on_activation_counter                           (activation_counter)
#  index_gtags_on_customer_id                                  (customer_id)
#  index_gtags_on_event_id                                     (event_id)
#  index_gtags_on_event_id_and_tag_uid_and_activation_counter  (event_id,tag_uid,activation_counter) UNIQUE
#  index_gtags_on_tag_uid                                      (tag_uid)
#
# Foreign Keys
#
#  fk_rails_084fd46c5e  (event_id => events.id)
#  fk_rails_70b4405c01  (customer_id => customers.id)
#

class Gtag < ActiveRecord::Base
  include Credentiable

  STANDARD = "standard".freeze
  CARD = "card".freeze
  SIMPLE = "simple".freeze
  WRISTBAND = "wristband".freeze

  # UID categorization of the gtags
  UID_FORMATS = [STANDARD, CARD, SIMPLE].freeze

  # Physical type of the gtags
  FORMATS = [CARD, WRISTBAND].freeze

  # Gtag limits
  DEFINITIONS = { mifare_classic: { entitlement_limit: 15, credential_limit: 15 },
                  ultralight_ev1: { entitlement_limit: 40, credential_limit: 32 },
                  ultralight_c:   { entitlement_limit: 56, credential_limit: 32 } }.freeze

  SETTINGS = [:format, :gtag_type, :maximum_gtag_balance, :cards_can_refund, :gtag_deposit,
              :wristbands_can_refund].freeze

  belongs_to :event
  has_many :transactions, dependent: :restrict_with_error

  validates :tag_uid, uniqueness: { scope: [:event_id, :activation_counter] }
  validates :tag_uid, presence: true

  scope :query_for_csv, ->(event) { event.gtags.select("id, tag_uid, banned, loyalty, format") }
  scope :banned, -> { where(banned: true) }

  alias_attribute :reference, :tag_uid

  def recalculate_balance
    ts = transactions.credit.select { |t| t.status_code.zero? }.sort_by(&:gtag_counter)
    self.credits = ts.map(&:credits).sum
    self.refundable_credits = ts.map(&:refundable_credits).sum
    self.final_balance = ts.last&.final_balance.to_f
    self.final_refundable_balance = ts.last&.final_refundable_balance.to_f

    save
  end

  def solve_inconsistent
    ts = transactions.credit.order(gtag_counter: :asc).select { |t| t.status_code.zero? }
    transaction = transactions.credit.find_by(gtag_counter: 0)
    atts = assignation_atts.merge(gtag_counter: 0, gtag_id: id, activation_counter: 0, final_balance: 0, final_refundable_balance: 0)
    transaction = CreditTransaction.write!(event, "correction", :device, nil, nil, atts) unless transaction
    credits = ts.last&.final_balance.to_f - ts.map(&:credits).sum
    refundable_credits = ts.last&.final_refundable_balance.to_f - ts.map(&:refundable_credits).sum

    transaction.update! credits: credits, refundable_credits: refundable_credits
    recalculate_balance
  end

  def refundable_money
    refundable_credits.to_i * event.credit.value
  end

  def valid_balance?
    credits == final_balance && refundable_credits == final_refundable_balance
  end

  def assigned?
    customer.present?
  end

  def assignation_atts
    { customer_tag_uid: tag_uid }
  end

  # Defines a method with a question mark for each gtag format which returns if the gtag has that format
  FORMATS.each do |method_name|
    define_method "#{method_name}?" do
      format == method_name
    end
  end

  def can_refund?
    card = card? && event.cards_can_refund?
    wristband = wristband? && event.wristbands_can_refund?
    return true if loyalty? || card || wristband
  end
end
