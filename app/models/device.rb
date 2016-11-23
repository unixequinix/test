# == Schema Information
#
# Table name: devices
#
#  asset_tracker :string
#  created_at    :datetime         not null
#  device_model  :string
#  imei          :string
#  mac           :string
#  serial_number :string
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_devices_on_mac_and_imei_and_serial_number  (mac,imei,serial_number) UNIQUE
#

class Device < ActiveRecord::Base
  before_validation :upcase_asset_tracker!

  SETTINGS = [:min_version_apk, :private_zone_password, :fast_removal_password, :uid_reverse, :gtag_whitelist,
              :touchpoint_update_online_orders, :pos_update_online_orders, :topup_initialize_gtag, :autotopup_enabled,
              :cypher_enabled, :gtag_blacklist, :event_id, :sync_time_event_parameters, :sync_time_server_date,
              :sync_time_basic_download, :sync_time_tickets, :sync_time_gtags, :sync_time_customers].freeze

  def self.transactions_count(event) # rubocop:disable Metrics/MethodLength
    sql = <<-SQL
      SELECT to_json(json_agg(row_to_json(cep)))
      FROM (
        SELECT transaction.device_uid, count(transaction.device_uid) as transactions_count,
        (
          SELECT type
          FROM transactions
          WHERE transactions.device_uid = transaction.device_uid
          AND transactions.event_id = #{event.id}
          AND transactions.type = 'DeviceTransaction'
          ORDER BY device_created_at DESC
          LIMIT 1
        ) as action
        FROM (SELECT device_uid FROM transactions WHERE transactions.event_id = #{event.id}) as transaction
        GROUP BY device_uid
        ORDER BY device_uid
      ) cep
    SQL
    conn = ActiveRecord::Base.connection
    sql = conn.select_value(sql)
    conn.close
    JSON.parse(sql)
  end

  def upcase_asset_tracker!
    asset_tracker.upcase! if asset_tracker
  end
end
