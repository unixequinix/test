class Events::DirectClaimsController < Events::ClaimsController
  skip_before_action :require_permission!

  def create
    @claim = generate_claim
    @claim.start_claim!
    if Management::RefundManager.new(current_profile).execute
      RefundService.new(@claim)
        .create(amount: current_profile.refundable_money_amount,
                currency: current_event.currency,
                message: "Created direct refund",
                payment_solution: "direct",
                status: "SUCCESS")
      redirect_to success_event_refunds_url(current_event) and return
    end

    redirect_to error_event_refunds_url(current_event)
  end

  private

  def service_type
    Claim::EASY_PAYMENT_GATEWAY
  end
end
