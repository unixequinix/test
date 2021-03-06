module Api
  module V1
    module Events
      class TicketsController < Api::V1::EventsController
        before_action :set_modified

        def index
          tickets = tickets_sql || []
          date = @current_event.tickets.maximum(:updated_at)&.httpdate

          render_entity(tickets, date)
        end

        def show
          ticket = @current_event.tickets.find_by(code: params[:id]) || @current_event.tickets.find_by(id: params[:id])

          render(json: :not_found, status: :not_found) && return unless ticket
          render(json: ticket, serializer: TicketSerializer)
        end

        def banned
          tickets = tickets_sql(true) || []
          date = @current_event.tickets.banned.maximum(:updated_at)&.httpdate

          render_entity(tickets, date)
        end

        private

        # * have ticket_type with catalog_item
        def tickets_sql(only_banned = false)
          sql = <<-SQL
            SELECT json_strip_nulls(array_to_json(array_agg(row_to_json(t))))
            FROM (
              SELECT
                tickets.code as reference,
                tickets.redeemed,
                tickets.purchaser_first_name,
                tickets.purchaser_last_name,
                tickets.purchaser_email,
                tickets.banned,
                tickets.updated_at,
                tickets.ticket_type_id,
                customer_id

              FROM tickets

              INNER JOIN ticket_types
                ON ticket_types.id = tickets.ticket_type_id
                AND ticket_types.hidden = false
                AND ticket_types.catalog_item_id IS NOT NULL

              WHERE tickets.event_id = #{@current_event.id}
              #{"AND tickets.updated_at > '#{@modified}'" if @modified}
              #{'AND tickets.banned = TRUE' if only_banned}
            ) t
          SQL
          ActiveRecord::Base.connection.select_value(sql)
        end
      end
    end
  end
end
