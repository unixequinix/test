require 'rails_helper'

RSpec.describe Entitlement, type: :model do

  it { is_expected.to validate_presence_of(:name) }

end
