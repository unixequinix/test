class Transactions::Base < ActiveJob::Base
  SEARCH_ATTS = %w(event_id device_uid device_db_index device_created_at_fixed gtag_counter activation_counter).freeze

  def perform(atts)
    atts = preformat_atts(atts)
    klass = Transaction.class_for_type(atts[:type])
    atts[:type] = klass.to_s
    gtag_atts = { tag_uid: atts[:customer_tag_uid], event_id: atts[:event_id], activation_counter: atts[:activation_counter] }

    begin
      transaction = klass.transaction(requires_new: true) { klass.find_or_create_by(atts.slice(*SEARCH_ATTS)) }
      atts[:gtag_id] = Gtag.transaction(requires_new: true) { Gtag.find_or_create_by(gtag_atts).id } if atts[:customer_tag_uid].present?
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    return if transaction.executed?
    transaction.update!(column_attributes(klass, atts))

    return unless atts[:status_code].to_i.zero?
    execute_operations(atts.merge(transaction_id: transaction.id))
    transaction.update! executed: true
  end

  def execute_operations(atts)
    children = self.class.descendants
    children.each { |klass| klass.perform_later(atts) if klass::TRIGGERS.include? atts[:action] }
  end

  def column_attributes(klass, atts)
    atts.slice(*klass.column_names.map(&:to_sym))
  end

  def preformat_atts(atts)
    atts[:activation_counter] = 1 if atts[:activation_counter].to_i.zero?
    atts[:transaction_origin] = Transaction::ORIGINS[:device]
    atts[:station_id] = Station.find_by(event_id: atts[:event_id], station_event_id: atts[:station_id])&.id
    atts[:customer_tag_uid] = atts[:customer_tag_uid].to_s.upcase if atts.key?(:customer_tag_uid)
    atts[:order_item_counter] = atts[:order_item_id] if atts.key?(:order_item_id)
    atts[:device_created_at_fixed] = atts[:device_created_at]
    atts.delete(:sale_items_attributes) if atts[:sale_items_attributes].blank?
    atts
  end

  def self.inherited(klass)
    @descendants ||= []
    @descendants += klass.to_s.split("::").last.eql?("Base") ? klass.descendants : [klass]
  end

  def self.descendants
    @descendants || []
  end
end
