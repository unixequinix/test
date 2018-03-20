require "rails_helper"

RSpec.describe Api::V1::DevicesController, type: :controller do
  let(:user) { create(:user) }
  let!(:team) { create(:team) }
  let(:device) { build(:device, team_id: team.id) }
  let(:params) { { mac: device.mac, team_id: team.id } }

  describe "POST create" do
    before do
      team.users << user
      http_login(user.email, user.access_token)
    end

    it "creates the device if it doesn't exist" do
      expect { post :create, params: params }.to change(Device, :count).by(1)
    end

    it "updates the device asset_tracker even if device is already saved" do
      device.save!
      params["asset_id"] = "H01"
      expect(device.asset_tracker).to be_nil
      post :create, params: params
      expect(device.reload.asset_tracker).to eq("H01")
    end
  end
end
