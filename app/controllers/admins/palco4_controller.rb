module Admins
  class Palco4Controller < BaseController
    def auth
      skip_authorization
      event = Event.find_by slug: cookies.signed[:event_slug]
      integration = event.palco4_ticketing_integrations.find(cookies.signed[:ticketing_integration_id])

      url = URI(GlownetWeb.config.palco4_auth_url)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(url)
      request.basic_auth(integration.client_key, integration.client_secret)
      response = http.request(request)

      begin
        body = JSON.parse(response.body)
      rescue JSON::ParserError
        body = { "token" => response.body }
      end

      redirect_to([:admins, event, :ticket_types], alert: t("alerts.not_authorized")) && return if body.eql?("ERROR")

      integration.update!(token: body["token"], userId: body["userId"], status: "active")
      redirect_to [:admins, event, integration], notice: "Palco4 login successful"
    end
  end
end