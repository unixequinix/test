# == Schema Information
#
# Table name: tickets
#
#  id                :integer          not null, primary key
#  ticket_type_id    :integer
#  number            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deleted_at        :datetime
#  purchaser_email   :string
#  purchaser_name    :string
#  purchaser_surname :string
#

FactoryGirl.define do
  factory :ticket do
    number { Faker::Lorem.word }
    ticket_type
    purchaser_email 'purchaser@email.com'
    purchaser_name 'John'
    purchaser_surname 'Doe'
  end
end
