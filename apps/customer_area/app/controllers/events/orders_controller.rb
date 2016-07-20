class Events::OrdersController < Events::BaseController
  before_action :check_has_ticket!, only: [:show, :update]
  before_action :require_permission!, only: [:show, :update]
  before_action :require_credential!, only: [:show, :update]

  def show
    order = Order.includes(order_items: :catalog_item).find(params[:id])
    @order_presenters = []
    current_event.selected_payment_services.each do |payment_service|
      klass = "Orders::#{payment_service.to_s.camelize}Presenter".constantize
      @order_presenters << klass.new(current_event, order).with_params(params)
    end
  end

  def update
    @payment_service = params[:payment_service]
    @order = OrderManager.new(Order.find(params[:id])).sanitize_order
    params[:consumer_ip_address] = request.ip
    params[:consumer_user_agent] = request.user_agent
    klass = "Payments::#{@payment_service.camelize}::DataRetriever"
    @form_data = klass.constantize.new(current_event, @order).with_params(params)
    @order.start_payment!
  end

  private

  def require_permission!
    @order = Order.find(params[:id])
    return unless current_profile != @order.profile || @order.completed? || @order.expired?
    flash.now[:error] = I18n.t("alerts.order_complete") if @order.completed?
    flash.now[:error] = I18n.t("alerts.order_expired") if @order.expired?
    redirect_to event_url(current_event)
  end

  def require_credential!
    return if current_profile.active_assignments.present?
    redirect_to event_url(current_event)
  end
end
