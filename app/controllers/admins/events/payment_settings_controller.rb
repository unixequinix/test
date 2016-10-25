class Admins::Events::PaymentSettingsController < Admins::Events::BaseController
  def index
    @event = Event.friendly.find(params[:event_id])
    @payment_parameters = current_event.event_parameters.where(
      parameters: {
        group: @event.selected_payment_services.map { |ps| EventDecorator::PAYMENT_PLATFORMS[ps] },
        category: "payment"
      }
    ).includes(:parameter)
  end

  # TODO: Move this method out from this controller, as it only applies to Stripe
  def new
    @event = Event.friendly.find(params[:event_id])
    stripe_account_id = Parameter.where(group: "stripe", category: "payment", name: "stripe_account_id")
    current_event.event_parameters.find_by(parameter: stripe_account_id)
    @payment_settings_form = StripePaymentActivationForm.new
  end

  # TODO: Move this method out from this controller, as it only applies to Stripe
  def create
    @event = Event.friendly.find(params[:event_id])
    @payment_service = "stripe"
    @payment_settings_form = StripePaymentActivationForm.new(activation_params)
    if @payment_settings_form.save(params, request)
      @event.save
      redirect_to admins_event_payment_settings_url(@event), notice: I18n.t("alerts.updated")
    else
      flash[:error] = @payment_settings_form.errors.full_messages.to_sentence
      render :new
    end
  end

  def edit
    @event = Event.friendly.find(params[:event_id])
    @payment_service = params[:id]
    @payment_platform = EventDecorator::PAYMENT_PLATFORMS[@payment_service.to_sym]
    event_parameters = current_event.event_parameters
                                    .where(parameters: { group: @payment_platform, category: "payment" })
                                    .joins(:parameter)
                                    .select("parameters.name, event_parameters.value")
                                    .as_json
    total = event_parameters.reduce({}) { |a, e| a.merge(e["name"] => e["value"]) }
    @payment_settings_form = "#{@payment_service.camelize}PaymentSettingsForm".constantize.new(total)
  end

  def update
    @event = Event.friendly.find(params[:event_id])
    @payment_service = params[:id]
    @payment_settings_form = "#{@payment_service.camelize}PaymentSettingsForm".constantize.new(settings_params)

    if @payment_settings_form.save(params, request)
      @event.save
      redirect_to admins_event_payment_settings_url(@event), notice: I18n.t("alerts.updated")
    else
      @payment_platform = EventDecorator::PAYMENT_PLATFORMS[@payment_service.to_sym]
      flash.now[:alert] = @payment_settings_form.errors.full_messages.to_sentence
      render :edit
    end
  end

  private

  def activation_params
    params_names = "#{@payment_service.camelize}PaymentActivationForm".constantize.attribute_set.map(&:name)
    params.require("#{@payment_service}_payment_activation_form").permit(params_names)
  end

  def settings_params
    params_names = "#{@payment_service.camelize}PaymentSettingsForm".constantize.attribute_set.map(&:name)
    params.require("#{@payment_service}_payment_settings_form").permit(params_names)
  end
end
