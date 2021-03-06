class TicketingIntegrationStubhub < TicketingIntegration
  belongs_to :event, inverse_of: :stubhub_ticketing_integrations

  store :data, accessors: %i[userId venue last_import_date], coder: JSON

  attr_accessor :ignore_last_import_date

  def self.policy_class
    TicketingIntegrationPolicy
  end

  def remote_events
    api_response(URI("#{GlownetWeb.config.stubhub_venues_url}?sVenues=#{venue}"))
  end

  def remote_event
    Hashie::Mash.new(remote_events.find { |e| e["sessionId"].eql? integration_event_id.to_i })
  end

  def import
    params = { sessions: integration_event_id }
    params = params.merge(date: last_import_date) if last_import_date && !ignore_last_import_date
    url = URI("#{GlownetWeb.config.stubhub_barcodes_url}?#{params.to_param}")

    update!(last_import_date: Time.zone.now - 1.minute)
    Ticketing::Palco4BaseImporter.perform_later(api_response(url), self)
  end
end
