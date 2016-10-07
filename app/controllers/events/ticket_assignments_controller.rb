class Events::TicketAssignmentsController < Events::BaseController
  def new
    @ticket_assignment_form = TicketAssignmentForm.new
  end

  def create
    @ticket_assignment_form = TicketAssignmentForm.new(ticket_assignment_parameters)
    if @ticket_assignment_form.save(Ticket.where(event: current_event),
                                    current_profile,
                                    current_event)
      flash[:notice] = I18n.t("alerts.created")
      redirect_to event_url(current_event)
    else
      flash.now[:error] = @ticket_assignment_form.errors.full_messages.join
      render :new
    end
  end

  def destroy
    customer_order_creator = CustomerOrderCreator.new
    @ticket_assignment = CredentialAssignment.find(params[:id])
    ticket = @ticket_assignment.credentiable
    customer_order_creator.delete(ticket)
    @credit_log = CreditWriter.reassign_ticket(ticket, :unassign) if ticket.credits.present?
    @ticket_assignment.unassign!
    flash[:notice] = I18n.t("alerts.unassigned")
    redirect_to event_url(current_event)
  end

  private

  def ticket_assignment_parameters
    params.require(:ticket_assignment_form).permit(:code)
  end
end