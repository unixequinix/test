class Admins::Events::CreditInconsistenciesController < Admins::Events::BaseController
  def index
    @issues = Profile.customer_credits_sum(current_event)
  end
end
