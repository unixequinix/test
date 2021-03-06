module Api::V2
  class Simple::GtagSerializer < ActiveModel::Serializer
    attributes :id, :tag_uid, :banned, :redeemed, :active, :consistent, :credits, :virtual_credits, :final_balance, :final_virtual_balance, :customer_id, :ticket_type_id

    def consistent
      object.valid_balance?
    end
  end
end
