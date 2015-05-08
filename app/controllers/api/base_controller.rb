class Api::BaseController < ApplicationController
  protect_from_forgery with: :null_session
  #before_action :restrict_access
  before_action :restrict_access_with_http

  serialization_scope :view_context

  private


  def restrict_access
    authenticate_or_request_with_http_token do |token, options|
      email = options.blank? ? nil : options[:email]
      @admin = email && Admin.find_by(email: email)
      # Is used to avoid Timing attacks
      # http://codahale.com/a-lesson-in-timing-attacks/
      @admin && ActiveSupport::SecurityUtils.secure_compare(
                                      @admin.access_token, token)
    end
  end

  def restrict_access_with_http
    authenticate_or_request_with_http_basic do |username, password|
      admin = Admin.find_for_database_authentication(email: username)
      admin.valid_password?(password)
    end
  end

end
