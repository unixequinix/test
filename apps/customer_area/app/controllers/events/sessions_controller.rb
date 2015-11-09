class Events::SessionsController < Events::BaseController
  layout 'event'
  skip_before_filter :authenticate_customer!

  def new
    @sign_up = params[:sign_up]
    @confirmed = params[:confirmed]
    @password_sent = params[:password_sent]
    @confirmation_sent = params[:confirmation_sent]
    @customer_login_form = CustomerLoginForm.new(Customer.new)
  end

  def create
    customer = Customer.find_by(email: permitted_params[:email], event: current_event)
    @customer_login_form = CustomerLoginForm.new(customer)
    if @customer_login_form.validate(permitted_params) && @customer_login_form.save
      authenticate_customer!
      redirect_to after_sign_in_path
    else
      @customer_login_form = CustomerLoginForm.new(Customer.new)
      flash.now[:error] = I18n.t('auth.failure.invalid', authentication_keys: 'email')
      render :new
    end
  end

  def destroy
    customer = current_customer
    warden.logout
    redirect_to after_sign_out_path
  end

  private

  def after_sign_out_path
    event_path(current_event)
  end

  def after_sign_in_path
    event_path(current_event)
  end

  def permitted_params
    params.require(:customer).permit(:email, :password, :event_id, :remember_me)
  end
end
