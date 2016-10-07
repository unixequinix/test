# == Schema Information
#
# Table name: access_transactions
#
#  id                 :integer          not null, primary key
#  event_id           :integer
#  transaction_origin :string
#  customer_tag_uid   :string
#  transaction_type   :string
#  station_id         :integer
#  device_db_index    :integer
#  device_created_at  :string
#  profile_id         :integer
#  access_id          :integer
#  direction          :integer
#  final_access_value :string
#  status_code        :integer
#  status_message     :string
#  device_uid         :string
#  operator_tag_uid   :string
#  created_at         :datetime
#  updated_at         :datetime
#  gtag_counter       :integer          default(0)
#  counter            :integer          default(0)
#

class AccessTransaction < Transaction
  belongs_to :access
  def self.mandatory_fields
    super + %w( access_id direction final_access_value )
  end

  def description
    "#{transaction_type.gsub('access', '').humanize}: #{access.catalog_item.name}"
  end
end