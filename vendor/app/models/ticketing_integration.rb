class TicketingIntegration < ApplicationRecord
  NAMES = { bizzabo: "TicketingIntegrationBizzabo", eventbrite: "TicketingIntegrationEventbrite", universe: "TicketingIntegrationUniverse", stubhub: "TicketingIntegrationStubhub", qwantiq: "TicketingIntegrationQwantiq", ticket_master: "TicketingIntegrationTicketMaster" }.freeze
  AUTOMATIC_INTEGRATIONS = %w[eventbrite universe].freeze

  has_many :ticket_types, dependent: :destroy

  belongs_to :event

  validates :token, presence: true, if: -> { active? }
  validates :type, uniqueness: { scope: %i[event_id integration_event_id] }, if: -> { integration_event_id.present? }

  enum status: { unauthorized: 0, active: 1, inactive: 2 }

  def name
    type.gsub("TicketingIntegration", "").underscore
  end

  def api_response(url, body = {}, header)
    http = Net::HTTP.new(url.host, url.port)

    if body.present?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      headers = { "Content-Type": "text/json" }

      request = Net::HTTP::Post.new(url, headers)
      request["Accept"] = "application/json"
      request.body = body.to_json
    else
      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"

      header.keys.each do |key|
        request[key.to_s] = header[key]
      end

      http.use_ssl = true
    end

    begin
      JSON.parse(http.request(request).body)
    rescue StandardError
      {}
    end
  end

  def import; end
end
