class Events::ConfirmationsController < Events::BaseController
  layout 'event'
  skip_before_filter :authenticate_customer!

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.find_by(email: permitted_params[:email], event: current_event)

    if !@customer.nil?
      CustomerMailer.confirmation_instructions_email(@customer).deliver_later
      flash[:notice] = t("auth.confirmations.send_instructions")
      redirect_to after_sending_confirmation_instructions_path
    else
      @customer = Customer.new
      flash.now[:error] = I18n.t('auth.failure.invalid', authentication_keys: 'email')
      render :new
    end
  end

  def show
    @customer = Customer.where(confirmation_token: params[:confirmation_token]).first
    if @customer.nil?
      flash.alert = t("errors.messages.not_found")
      redirect_to event_url(current_event)
    else
      flash.notice = t("auth.confirmations.confirmed")
      @customer.confirm!
      warden.set_user(@customer, scope: :admin)
      redirect_to after_confirmation_path
    end

  end

  private

  def redirect_if_token_empty!
    unless params.has_key?(:token)
      flash.alert = t("confirmations.token.empty")
      redirect_to :root and return
    end
  end

  def after_sending_confirmation_instructions_path
    new_event_sessions_path(current_event, confirmed: true)
  end

  def after_confirmation_path
    new_event_sessions_path(current_event, confirmed: true)
  end

  def permitted_params
    params.require(:customer)
      .permit(:email, :password, :password_confirmation, :confirmation_token)
      .merge(event_id: current_event.id)
  end
end