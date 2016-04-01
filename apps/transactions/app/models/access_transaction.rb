# == Schema Information
#
# Table name: access_transactions
#
#  id                           :integer          not null, primary key
#  event_id_id                  :integer
#  transaction_origin           :string
#  customer_tag_uid             :string
#  transaction_type             :string
#  operator_id_id               :integer
#  station_id_id                :integer
#  device_id_id                 :integer
#  device_db_index              :integer
#  device_created_at            :string
#  customer_event_profile_id_id :integer
#  access_entitlement_id_id     :integer
#  direction                    :integer
#  final_balance                :string
#  status_code                  :integer
#  status_message               :string
#

class AccessTransaction < Transaction
  belongs_to :device
  belongs_to :access_entitlement
end
