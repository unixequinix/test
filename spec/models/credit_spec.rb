# == Schema Information
#
# Table name: credits
#
#  id         :integer          not null, primary key
#  standard   :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#

require 'rails_helper'

RSpec.describe Credit, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
