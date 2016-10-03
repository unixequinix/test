Devise.setup do |config|
  Devise::SessionsController.layout "welcome_admin"

  # Mailer config
  config.mailer_sender = 'noreply@glownet.com'
  config.mailer = 'CustomerMailer'

  # ORM Used by devise
  require 'devise/orm/active_record'

  # Devise configuration
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 11
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 3..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete

  # Omniauth configuration
  config.omniauth_path_prefix = "/customers/auth"
  config.omniauth :twitter, "WZxGneMA0hC5ulbnKnC8yTzUv", "nSGGGRejLawheDDcPVz7ZCpvYOgthd01oekkKI54UBEU0cQY9A", callback_url: "http://localhost:3000/customers/auth/twitter/callback"
  config.omniauth :facebook, "1394605624176258", "d90124ea379382a52c021c1ecca619dd", callback_url: "http://localhost:3000/customers/auth/facebook/callback"
end
