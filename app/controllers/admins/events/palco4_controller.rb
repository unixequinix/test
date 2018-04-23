module Admins
  module Events
    class Palco4Controller < Admins::Events::BaseController
      protect_from_forgery
      before_action :set_integration

      # https://eur.stubhubtickets.com

      def index
        redirect_to(%i[admins palco4 auth]) && return unless @token

        # @sessions = @integration.api_response(URI("https://test.palco4.com/accessControlApi/sessions/info/json?sVenues=#{@integration.venue}"))
        @sessions = @integration.api_response(URI("https://eur.stubhubtickets.com/accessControlApi/sessions/info/json?sVenues=#{@integration.venue}"))
        @sessions = @sessions.select { |session| session["sessionUUID"].present? }
      end

      def connect
        if @integration.update(integration_event_id: params[:p4_uuid], integration_event_name: params[:p4_name], status: "active")
          redirect_to [:admins, @current_event, @integration, :import_tickets]
        else
          redirect_to [:admins, @current_event, @integration], alert: "Event already connected, choose another"
        end
      end

      def import_tickets
        @integration.import
        redirect_to [:admins, @current_event, :ticket_types], notice: "All tickets imported"
      end

      private

      def set_integration
        @integration = @current_event.palco4_ticketing_integrations.find(params[:ticketing_integration_id])
        authorize(@current_event.ticketing_integrations.new)
        cookies.signed[:ticketing_integration_id] = @integration.id
        cookies.signed[:event_slug] = @current_event.slug
        @token = @integration.token
      end
    end
  end
end
