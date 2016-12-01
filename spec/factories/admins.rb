# == Schema Information
#
# Table name: admins
#
#  access_token           :string           not null
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

FactoryGirl.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@glownet.com" }
    password "password"
    password_confirmation "password"
  end
end
