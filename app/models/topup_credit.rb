class TopupCredit < ApplicationRecord
  belongs_to :credit
  belongs_to :station, touch: true

  validates :amount, uniqueness: { scope: :station_id }, presence: true, numericality: { greater_than: 0 }
  validate :valid_topup_credit, on: :create

  scope(:visible, -> { where(hidden: [false, nil]) })

  def self.policy_class
    StationItemPolicy
  end

  def self.sort_column
    :amount
  end

  private

  def valid_topup_credit
    return unless station

    errors[:credit_count] << I18n.t("errors.messages.topup_credit_count") if station.topup_credits.visible.count > 6
  end
end
