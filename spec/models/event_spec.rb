# == Schema Information
#
# Table name: events
#
#  id         :integer          not null, primary key
#  name       :string
#  aasm_state :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Event, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
