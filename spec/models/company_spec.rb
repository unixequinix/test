# == Schema Information
#
# Table name: companies
#
#  access_token :string
#  name         :string           not null
#

require "spec_helper"

RSpec.describe Company, type: :model do
  let(:event) { create(:event) }
  subject { create(:company, event: event) }

  describe ".generate_access_token" do
    it "generates a random token to the company" do
      expect(subject.access_token).not_to be_nil
    end
  end
end
