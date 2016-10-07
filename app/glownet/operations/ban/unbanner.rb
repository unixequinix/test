class Operations::Ban::Unbanner < Operations::Base
  TRIGGERS = %w( ).freeze

  def perform(atts)
    event = Event.find(atts[:event_id])
    method_name = atts[:banneable_type].downcase.pluralize.to_sym
    obj = event.method(method_name).call.find(atts[:banneable_id])
    return if !obj.is_a?(Profile) && obj.assigned_profile&.banned?
    obj.update!(banned: false)
  end
end