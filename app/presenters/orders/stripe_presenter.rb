class Orders::StripePresenter < Orders::BasePresenter
  attr_accessor :event, :order

  def initialize(event, order)
    @event = event
    @order = order
  end

  def path
    "events/orders/stripe/payment_form"
  end

  def form_data
    Payments::Stripe::DataRetriever.new(@event, @order)
  end

  def payment_service
    "stripe"
  end
end