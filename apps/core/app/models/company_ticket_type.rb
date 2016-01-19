# == Schema Information
#
# Table name: company_ticket_types
#
#  id                  :integer          not null, primary key
#  company_id          :integer
#  preevent_product_id :integer
#  event_id            :integer
#  name                :string
#  code                :string
#  deleted_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class CompanyTicketType < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :event
  belongs_to :preevent_product
  belongs_to :company

  # TODO: Add validation to internal_ticket_type
  validates :name, presence: true
end
