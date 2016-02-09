class Events::RefundsController < Events::BaseController
  skip_before_action :authenticate_customer!, only: [:create, :tipalti_success]
  skip_before_filter :verify_authenticity_token, only: [:create, :tipalti_success]
  skip_before_action :check_has_gtag!, only: [:create, :tipalti_success]

  def create
    response = Nokogiri::XML(request.body.read)
    operations = response.xpath("//payfrex-response/operations/operation")
    operations.each do |operation|
      operation_hash = Hash.from_xml(operation.to_s)
      @claim = Claim.find_by(number: operation_hash["operation"]["merchantTransactionId"])
      next unless @claim
      RefundService.new(@claim, current_event)
        .create(amount: operation_hash["operation"]["amount"],
                currency: operation_hash["operation"]["currency"],
                message: operation_hash["operation"]["message"],
                operation_type: operation_hash["operation"]["operationType"],
                gateway_transaction_number: operation_hash["operation"]["payFrexTransactionId"],
                payment_solution: operation_hash["operation"]["paymentSolution"],
                status: operation_hash["operation"]["status"])
    end
    render nothing: true
  end

  def tipalti_success
    @claim = Claim.where(customer_event_profile_id: params[:customerID],
                         service_type: "tipalti",
                         aasm_state: :in_progress)
             .order(id: :desc).first

    redirect_to error_event_refunds_url(current_event) && return unless @claim

    RefundService.new(@claim, current_event)
      .create(amount: @claim.gtag.refundable_amount_after_fee("tipalti"),
              currency: I18n.t("currency_symbol"),
              message: "Created tipalti refund",
              payment_solution: "tipalti",
              status: "SUCCESS")
    redirect_to success_event_refunds_url(current_event)
  end

  def success
  end

  def error
  end
end
