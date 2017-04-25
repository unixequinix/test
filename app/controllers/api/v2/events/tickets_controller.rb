class Api::V2::Events::TicketsController < Api::V2::BaseController
  before_action :set_ticket, only: %i[show update destroy]

  # GET /tickets
  def index
    @tickets = @current_event.tickets
    authorize @tickets

    render json: @tickets, each_serializer: Api::V2::Simple::TicketSerializer
  end

  # GET /tickets/1
  def show
    render json: @ticket
  end

  # POST /tickets
  def create
    @ticket = @current_event.tickets.new(ticket_params)
    authorize @ticket

    if @ticket.save
      render json: @ticket, status: :created, location: @ticket
    else
      render json: @ticket.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tickets/1
  def update
    if @ticket.update(ticket_params)
      render json: @ticket
    else
      render json: @ticket.errors, status: :unprocessable_entity
    end
  end

  # DELETE /tickets/1
  def destroy
    @ticket.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ticket
    @ticket = @current_event.tickets.find(params[:id])
    authorize @ticket
  end

  # Only allow a trusted parameter "white list" through.
  def ticket_params
    params.require(:ticket).permit(:ticket_type_id, :code, :redeemed, :banned, :purchaser_first_name, :purchaser_last_name, :purchaser_email, :customer_id) # rubocop:disable Metrics/LineLength
  end
end