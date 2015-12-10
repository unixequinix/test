class Admins::Events::TicketsController < Admins::Events::CheckinBaseController
  before_filter :set_presenter, only: [:index, :search]

  def index
    respond_to do |format|
      format.html
      format.csv { send_data(Csv::CsvExporter.to_csv(Ticket.selected_data(current_event.id)))}
    end
  end

  def search
    render :index
  end

  def show
    @ticket = @fetcher.tickets.includes(admissions: [:customer_event_profile, customer_event_profile: :customer]).find(params[:id])
  end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Ticket.new(permitted_params)
    if @ticket.save
      flash[:notice] = I18n.t('alerts.created')
      redirect_to admins_event_tickets_url
    else
      flash[:error] = I18n.t('alerts.error')
      render :new
    end
  end

  def edit
    @ticket = @fetcher.tickets.find(params[:id])
  end

  def update
    @ticket = @fetcher.tickets.find(params[:id])
    if @ticket.update(permitted_params)
      flash[:notice] = I18n.t('alerts.updated')
      redirect_to admins_event_ticket_url(current_event, @ticket)
    else
      flash[:error] = I18n.t('alerts.error')
      render :edit
    end
  end

  def destroy
    @ticket = @fetcher.tickets.find(params[:id])
    if @ticket.destroy
      flash[:notice] = I18n.t('alerts.destroyed')
      redirect_to admins_event_tickets_url
    else
      flash[:error] = @ticket.errors.full_messages.join(". ")
      redirect_to admins_event_tickets_url
    end
  end

  def destroy_multiple
    if tickets = params[:tickets]
      @fetcher.tickets.where(id: tickets.keys).each do |ticket|
        if !ticket.destroy
          flash[:error] = ticket.errors.full_messages.join(". ")
        end
      end
    end
    redirect_to admins_event_tickets_url
  end

  private
  def set_presenter
    @list_model_presenter = ListModelPresenter.new(
      model_name: "Ticket".constantize.model_name,
      fetcher: @fetcher.tickets,
      search_query: params[:q],
      page: params[:page],
      include_for_all_items: [:ticket_type, :assigned_admission],
      context: view_context
    )
  end

  def permitted_params
    params.require(:ticket).permit(:event_id, :number, :ticket_type_id, :purchaser_name, :purchaser_surname, :purchaser_email)
  end

end
