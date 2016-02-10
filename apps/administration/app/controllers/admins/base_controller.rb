class Admins::BaseController < ApplicationController
  layout "admin"
  protect_from_forgery
  before_action :ensure_admin
  before_action :write_locale_to_session
  before_action :authenticate_admin!
  helper_method :warden, :admin_signed_in?, :current_admin
  helper_method :current_event

  def current_event
    @current_event || Event.new
  end

  def warden
    request.env["warden"]
  end

  def authenticate_admin!
    warden.authenticate!(:admin_password, scope: :admin)
  end

  def logout_admin!
    warden.logout(:admin)
  end

  def ensure_admin
    return if admin_signed_in?
    logout_admin!
    false
  end

  def admin_signed_in?
    !current_admin.nil?
  end

  def current_admin
    @current_admin ||= Admin.find(warden.user(:admin)["id"]) unless
        !warden.authenticated?(:admin) ||
        Admin.where(id: warden.user(:admin)["id"]).empty?
  end

  private

  def write_locale_to_session
    super(I18n.available_locales)
  end
end
