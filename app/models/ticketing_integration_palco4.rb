class TicketingIntegrationPalco4 < TicketingIntegration
  belongs_to :event, inverse_of: :palco4_ticketing_integrations

  store :data, accessors: %i[userId venue last_import_date], coder: JSON

  def self.policy_class
    TicketingIntegrationPalco4
  end

  def import
    params = { sessions: integration_event_id }
    params = params.merge(date: last_import_date) if last_import_date
    url = URI("https://eur.stubhubtickets.com/accessControlApi/barcodes/getListFromActiveSessions/json?#{params.to_param}")
    # url = URI("https://test.palco4.com/accessControlApi/barcodes/getListFromActiveSessions/json?#{params}")

    update!(last_import_date: Time.zone.now - 1.minute)

    response = api_response(url)
    response&.each { |ticket| Ticketing::Palco4Importer.perform_later(ticket, self) }
  end
end
