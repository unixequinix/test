class Operations::Base < ActiveJob::Base
  SEARCH_ATTS = %w( event_id device_uid device_db_index device_created_at )

  def perform(atts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    klass = "#{ atts[:transaction_category] }_transaction".classify.constantize
    obj_atts = column_attributes(klass, atts)

    created_at = atts[:device_created_at]
    atts[:device_created_at] = Time.zone.parse(created_at).to_s if created_at
    obj_atts[:device_created_at] = atts[:device_created_at]

    obj = klass.find_by(atts.slice(*SEARCH_ATTS))
    return obj if obj

    status_ok = atts[:status_code].to_i.zero?
    return portal_write(atts) unless status_ok

    Gtag.find_or_create_by!(tag_uid: atts[:customer_tag_uid], event_id: atts[:event_id])
    profile_id = Profile::Checker.for_transaction(obj_atts)
    parse_attributes!(atts, obj_atts, profile_id: profile_id)
    obj = klass.create(obj_atts)
    atts.merge!(transaction_id: obj.id, profile_id: profile_id)
    children = self.class.descendants
    children.each { |d| d.perform_later(atts) if d::TRIGGERS.include? atts[:transaction_type] }
    obj
  end

  def portal_write(atts)
    klass = "#{ atts[:transaction_category] }_transaction".classify.constantize
    obj_atts = column_attributes(klass, atts)
    obj_atts.delete_if { |key, value| key.to_s.split("_").last.eql?("id") && value.zero? }
    klass.create!(obj_atts)
  end

  def column_attributes(klass, atts)
    atts.slice(*klass.column_names.map(&:to_sym))
  end

  def parse_attributes!(atts, obj_atts, extra_atts = {})
    sale_items = atts[:sale_items_attributes]
    obj_atts[:sale_items_attributes] = sale_items if sale_items
    obj_atts.merge!(extra_atts)
  end

  def self.inherited(klass)
    @descendants ||= []
    @descendants += klass.to_s.split("::").last.eql?("Base") ? klass.descendants : [klass]
  end

  def self.descendants
    @descendants || []
  end
end
