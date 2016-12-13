# == Schema Information
#
# Table name: catalog_items
#
#  initial_amount  :integer
#  max_purchasable :integer
#  min_purchasable :integer
#  name            :string
#  step            :integer
#  type            :string           not null
#  value           :decimal(8, 2)    default(1.0), not null
#
# Indexes
#
#  index_catalog_items_on_event_id  (event_id)
#
# Foreign Keys
#
#  fk_rails_6d2668d4ae  (event_id => events.id)
#

class Access < CatalogItem
  has_one :entitlement, dependent: :destroy

  has_many :access_transactions, dependent: :destroy
  has_many :access_control_gates, dependent: :destroy

  accepts_nested_attributes_for :entitlement, allow_destroy: true

  before_validation :set_infinite_values, if: :infinite?
  before_validation :set_memory_length

  validates :initial_amount, :step, :max_purchasable, :min_purchasable, presence: true
  validates :max_purchasable, numericality: { less_than: 128 }
  validate :min_max_congruency

  scope :infinite, -> { includes(:entitlement).where(entitlements: { mode: Entitlement::ALL_PERMANENT }) }
  delegate :infinite?, to: :entitlement

  private

  def set_infinite_values
    self.min_purchasable = 0
    self.max_purchasable = 1
    self.step = 1
    self.initial_amount = 0
  end

  def set_memory_length
    entitlement.memory_length = 2 if max_purchasable.to_i > 7
  end

  def min_max_congruency
    return if min_purchasable.to_i <= max_purchasable.to_i
    errors[:min_purchasable] << I18n.t("errors.messages.greater_than_maximum")
  end
end
