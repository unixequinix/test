class Payments::PaypalNvp::AutotopupPayer < Payments::PaypalNvp::BasePayer
  include Payments::AutomaticRefundable

  def initialize(params)
    super(params)
    @method = "regular"
  end

  def start(customer_order_creator, credit_writer)
    return if @gateway
    @order.start_payment!
    charge_object = charge
    return charge_object unless charge_object["ACK"] == "Success"
    return unless create_agreement(charge_object)
    notify_payment(charge_object, customer_order_creator, credit_writer)
    automatic_refund(@payment, @order.total, @params[:payment_service_id])
    charge_object
  end

  private

  def notify_payment(charge, _customer_order_creator, _customer_credit_creator)
    return unless charge["ACK"] == "Success"
    @payment = create_payment(@order, charge, @method)
    @order.complete!
    send_mail_for(@profile.customer)
  end

  def send_mail_for(customer)
    AgreementMailer.accepted_email(customer).deliver_later
  end
end