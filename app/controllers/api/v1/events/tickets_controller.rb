class Api::V1::Events::TicketsController < Api::V1::Events::BaseController
  before_action :set_modified

  def index
    tickets = tickets_sql || []
    date = current_event.tickets.maximum(:updated_at)&.httpdate

    render_entity(tickets, date)
  end

  def show
    ticket = current_event.tickets.find_by_code(params[:id])

    render(json: :not_found, status: :not_found) && return unless ticket
    render(json: ticket, serializer: Api::V1::TicketSerializer)
  end

  private

  def tickets_sql # rubocop:disable Metrics/MethodLength
    sql = <<-SQL
      SELECT array_to_json(array_agg(row_to_json(t)))
      FROM (
        SELECT
          tickets.code as reference,
          tickets.redeemed,
          tickets.purchaser_first_name,
          tickets.purchaser_last_name,
          tickets.purchaser_email,
          tickets.banned,
          tickets.updated_at,
          ticket_types.catalog_item_id,
          customer_id

        FROM tickets

        INNER JOIN ticket_types
          ON ticket_types.id = tickets.ticket_type_id
          AND ticket_types.hidden = false

        WHERE tickets.event_id = #{current_event.id} #{"AND tickets.updated_at > '#{@modified}'" if @modified}
      ) t
    SQL
    ActiveRecord::Base.connection.select_value(sql)
  end
end
