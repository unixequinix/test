class Api::V1::Events::TicketsController < Api::V1::Events::BaseController
  def index
    modified = request.headers["If-Modified-Since"]
    tickets = @fetcher.sql_tickets(modified) || []

    if tickets.present?
      date = JSON.parse(tickets).map { |pr| pr["updated_at"] }.sort.last
      response.headers["Last-Modified"] = date.to_datetime.httpdate
    end
    render(json: tickets)
  end

  def show
    serializer = Api::V1::TicketWithCustomerSerializer
    @ticket = current_event.tickets.find_by_code(params[:id])
    render(json: @ticket, serializer: serializer) && return if @ticket
    render(json: :not_found, status: :not_found)
  end
end
