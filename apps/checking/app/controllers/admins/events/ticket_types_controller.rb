class Admins::Events::TicketTypesController < Admins::Events::CheckingBaseController

  def index
    @ticket_types = TicketType.where(event_id: current_event.id).page(params[:page]).includes(:entitlements)
    respond_to do |format|
      format.html
      format.csv { send_data(Csv::CsvExporter.to_csv(TicketType.where(event_id: current_event.id)))}
    end
  end

  def new
    @ticket_type = TicketType.new
  end

  def create
    @ticket_type = TicketType.new(permitted_params)
    if @ticket_type.save
      flash[:notice] = I18n.t('alerts.created')
      redirect_to admins_event_ticket_types_url
    else
      flash[:error] = I18n.t('alerts.error')
      render :new
    end
  end

  def edit
    @ticket_type = TicketType.find(params[:id])
  end

  def update
    @ticket_type = TicketType.find(params[:id])
    if @ticket_type.update(permitted_params)
      flash[:notice] = I18n.t('alerts.updated')
      redirect_to admins_event_ticket_types_url
    else
      flash[:error] = I18n.t('alerts.error')
      render :edit
    end
  end

  def destroy
    @ticket_type = TicketType.find(params[:id])
    if @ticket_type.destroy
      flash[:notice] = I18n.t('alerts.destroyed')
      redirect_to admins_event_ticket_types_url
    else
      flash[:error] = @ticket_type.errors.full_messages.join(". ")
      redirect_to admins_event_ticket_types_url
    end
  end

  private

  def permitted_params
    params.require(:ticket_type).permit(:event_id, :name, :simplified_name, :company, :credit, entitlement_ids: [])
  end

end
