class Events::RegistrationsController < Devise::RegistrationsController
  layout "customer"

  before_action :configure_permitted_parameters
  before_action :set_event

  def create
    build_resource(sign_up_params)

    if verify_recaptcha(model: resource) && resource.save
      flash[:notice] = t('email.confirmation.flash_message')
      redirect_to customer_event_session_path(@current_event)
    else
      set_minimum_password_length
      respond_with resource
    end
  end

  def change_password
    redirect_to :event_login unless customer_signed_in?
  end

  private

  def build_resource(hash = {}) # rubocop:disable Metrics/AbcSize
    self.resource = session[:customer_id] ? @current_event.customers.find(session[:customer_id]) : @current_event.customers.new
    resource.attributes = hash.merge(anonymous: false)

    return unless session[:omniauth]

    token = Devise.friendly_token[0, 20]
    name = session[:omniauth]["info"]["name"].split(" ")
    first_name = session[:omniauth]["info"]["first_name"] || name.first
    last_name = session[:omniauth]["info"]["last_name"] || name.second
    resource.provider = session[:omniauth]["provider"]
    resource.uid = session[:omniauth]["uid"]
    resource.email = session[:omniauth]["info"]["email"]
    resource.first_name = first_name
    resource.last_name = last_name
    resource.password = token
    resource.password_confirmation = token
    resource.agreed_on_registration = true
    resource.anonymous = false
    session.delete(:omniauth) && resource.valid?
  end

  def configure_permitted_parameters
    customer = %i[first_name last_name phone postcode address city country gender birthdate provider uid agreed_on_registration]

    devise_parameter_sanitizer.permit(:account_update, keys: customer)
    devise_parameter_sanitizer.permit(:sign_up, keys: customer)
  end

  def after_update_path_for(_resource)
    customer_root_path(@current_event)
  end

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def set_event
    @current_event = Event.friendly.find(params[:event_id] || params[:id])
    @current_customer = current_customer
  end
end
