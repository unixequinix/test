# == Schema Information
#
# Table name: transactions
#
#  action                      :string
#  activation_counter          :integer
#  counter                     :integer
#  credits                     :float
#  device_db_index             :integer
#  direction                   :integer
#  final_access_value          :string
#  final_balance               :float
#  final_refundable_balance    :float
#  gtag_counter                :integer
#  items_amount                :float
#  operator_activation_counter :integer
#  operator_value              :string
#  order_item_counter          :integer
#  payment_gateway             :string
#  payment_method              :string
#  price                       :float
#  priority                    :integer
#  refundable_credits          :float
#  status_code                 :integer
#  status_message              :string
#  ticket_code                 :string
#  transaction_origin          :string
#  type                        :string
#
# Indexes
#
#  index_transactions_on_access_id            (access_id)
#  index_transactions_on_catalog_item_id      (catalog_item_id)
#  index_transactions_on_customer_id          (customer_id)
#  index_transactions_on_event_id             (event_id)
#  index_transactions_on_gtag_id              (gtag_id)
#  index_transactions_on_operator_station_id  (operator_station_id)
#  index_transactions_on_order_id             (order_id)
#  index_transactions_on_station_id           (station_id)
#  index_transactions_on_type                 (type)
#
# Foreign Keys
#
#  fk_rails_35e85c4b19  (catalog_item_id => catalog_items.id)
#  fk_rails_4855921d15  (event_id => events.id)
#  fk_rails_59d791a33f  (order_id => orders.id)
#  fk_rails_984bd8f159  (customer_id => customers.id)
#  fk_rails_9bf7d8b3a6  (gtag_id => gtags.id)
#  fk_rails_f51c7f5cfc  (station_id => stations.id)
#

class OrderTransaction < Transaction
  belongs_to :order
  belongs_to :order_item
  belongs_to :catalog_item

  def self.mandatory_fields
    super + %w( catalog_item_id )
  end
end
