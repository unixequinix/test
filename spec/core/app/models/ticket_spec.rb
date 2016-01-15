# == Schema Information
#
# Table name: tickets
#
#  id                :integer          not null, primary key
#  ticket_type_id    :integer          not null
#  number            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deleted_at        :datetime
#  purchaser_email   :string
#  purchaser_name    :string
#  purchaser_surname :string
#  event_id          :integer          not null
#

require 'rails_helper'

RSpec.describe Ticket, type: :model do
  it { is_expected.to validate_presence_of(:number) }
  it { is_expected.to validate_presence_of(:number) }
  it { is_expected.to validate_presence_of(:ticket_type) }

  it do
    ticket = FactoryGirl.build(:ticket)

    expect(ticket.valid?).to be(true)
  end
end
