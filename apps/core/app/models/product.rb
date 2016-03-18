# == Schema Information
#
# Table name: products
#
#  id          :integer          not null, primary key
#  name        :string
#  is_alcohol  :boolean
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :string
#  event_id    :integer
#

class Product < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :event
  has_and_belongs_to_many :vouchers

  validates :name, :event_id, presence: true
end
