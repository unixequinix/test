class Api::V2::RefundSerializer < ActiveModel::Serializer
  attributes :id, :amount, :status, :fee, :field_a, :field_b, :customer_id
end
