class Orders::PaypalPresenter
  attr_accessor :event, :order

  def initialize(event, order)
    @event = event
    @order = order
  end

  def path
    "events/orders/paypal_payment_form"
  end

  def form_data
    Payments::BraintreeDataRetriever.new(@event, @order)
  end

  def payment_service
    "paypal"
  end
end
