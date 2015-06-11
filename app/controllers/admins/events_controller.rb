class Admins::EventsController < Admins::BaseController

  def show
    @event = current_event
  end

  def edit
    @event = current_event
  end

  def update
    @event = Event.friendly.find(params[:id])
    if @event.update(permitted_params)
      flash[:notice] = I18n.t('alerts.updated')
      redirect_to admins_event_url(@event)
    else
      flash[:error] = I18n.t('alerts.error')
      render :edit
    end
  end

  private

  def permitted_params
    params.require(:event).permit(:aasm_state, :name, :location, :start_date, :end_date, :description, :support_email, :style, :logo, :background_type, :background)
  end

end
