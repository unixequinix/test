class Transactions::Base < ApplicationJob
  SEARCH_ATTS = %i[event_id device_uid device_db_index device_created_at_fixed].freeze

  queue_as :default

  def perform(atts)
    atts = preformat_atts(atts.symbolize_keys)
    klass = Transaction.class_for_type(atts[:type])
    atts[:type] = klass.to_s

    begin
      transaction = klass.find_or_initialize_by(atts.slice(*SEARCH_ATTS))
      return unless transaction.new_record?
      transaction.update! atts.slice(*klass.column_names.compact.map(&:to_sym))
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    Transactions::PostProcessor.perform_later(atts.merge(transaction_id: transaction.id))
  end

  def preformat_atts(atts)
    # this should slowly go, since data should come in the right format.
    atts[:transaction_origin] = Transaction::ORIGINS[:device]
    atts[:station_id] = Station.find_by(event_id: atts[:event_id], station_event_id: atts[:station_id])&.id
    atts[:order_item_counter] = atts[:order_item_id] if atts.key?(:order_item_id)
    atts[:device_created_at_fixed] = atts[:device_created_at].gsub(/(?<hour>[\+,\-][0-9][0-9])(?<minute>[0-9][0-9])/, '\k<hour>:\k<minute>')
    atts[:device_created_at] = atts[:device_created_at_fixed][0, 19]
    atts.delete(:sale_items_attributes) if atts[:sale_items_attributes].blank?
    atts
  end

  def self.inherited(klass)
    @descendants ||= []
    @descendants << klass
  end

  def self.descendants
    @descendants || []
  end
end
