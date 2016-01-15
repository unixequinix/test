class Events::GtagRegistrationsController < Events::BaseController
  before_action :check_event_status!
  before_action :check_has_not_gtag_registration!, only: [:new, :create]

  def new
    @gtag_registration_presenter = GtagRegistrationPresenter.new(current_event: current_event)
  end

  def create
    @gtag_registration_presenter = GtagRegistrationPresenter.new(current_event: current_event)
    gtag = Gtag.find_by(tag_uid: params[:tag_uid].strip.upcase, tag_serial_number: params[:tag_serial_number].strip.upcase, event: current_event)
    if !gtag.nil?
      @gtag_registration = current_customer_event_profile.gtag_registrations.build(gtag: gtag)
      if @gtag_registration.save
        flash[:notice] = I18n.t('alerts.created')
        GtagMailer.assigned_email(@gtag_registration).deliver_later
        redirect_to event_url(current_event)
      else
        flash[:error] = @gtag_registration.errors.full_messages.join('. ')
        render :new
      end
    else
      flash[:error] = I18n.t('alerts.gtag')
      render :new
    end
  end

  def destroy
    @gtag_registration = GtagRegistration.find(params[:id])
    @gtag_registration.unassign!
    flash[:notice] = I18n.t('alerts.unassigned')
    GtagMailer.unassigned_email(@gtag_registration).deliver_later
    redirect_to event_url(current_event)
  end

  private

  def check_event_status!
    return if current_event.gtag_registration?
    flash.now[:error] = I18n.t('alerts.error')
    redirect_to event_url(current_event)
  end

  def check_has_not_gtag_registration!
    return if current_customer_event_profile.assigned_gtag_registration.nil?
    redirect_to event_url(current_event), flash: { error: I18n.t('alerts.already_assigned') }
  end
end
