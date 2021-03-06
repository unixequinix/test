module Api::V2
  class EventSerializer < ActiveModel::Serializer
    attributes :id, :name, :start_date, :end_date, :slug, :logo, :background, :currency, :state, :open_topups, :open_refunds, :every_onsite_topup_fee, :onsite_initial_topup_fee, :online_initial_topup_fee, :gtag_deposit_fee, :online_refund_fee, :maximum_gtag_balance, :maximum_gtag_virtual_balance

    belongs_to :event_serie

    attribute :credit

    def credit
      Api::V2::CreditSerializer.new(object.credit)
    end
  end
end
