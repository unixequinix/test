# == Schema Information
#
# Table name: credential_transactions
#
#  id                   :integer          not null, primary key
#  event_id             :integer
#  transaction_origin   :string
#  transaction_category :string
#  transaction_type     :string
#  customer_tag_uid     :string
#  operator_tag_uid     :string
#  station_id           :integer
#  device_uid           :string
#  device_db_index      :integer
#  device_created_at    :string
#  ticket_id            :integer
#  profile_id           :integer
#  status_code          :integer
#  status_message       :string
#  ticket_code          :string
#  created_at           :datetime
#  updated_at           :datetime
#  gtag_counter         :integer          default(0)
#  counter              :integer          default(0)
#

class CredentialTransaction < Transaction
  belongs_to :ticket

  def description
    transaction_type.humanize
  end
end