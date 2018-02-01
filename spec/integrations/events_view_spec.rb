require 'rails_helper'

RSpec.describe "Test on Events view", type: :feature do
  let(:user) { create(:user, role: "glowball") }
  let!(:event) { create(:event, name: "Event Launched") }

  before(:each) do
    login_as(user, scope: :user)
    visit root_path
  end

  describe "create new event" do
    it "filling name" do
      within("#new_event") { fill_in 'event_name', with: "NewEvent" }
      expect { find("input[name=commit]").click }.to change(Event, :count).by(1)
      expect(page).to have_current_path(admins_event_path("newevent"))
    end

    it "without filling name" do
      expect { find("input[name=commit]").click }.not_to change(Event, :count)
    end

    it "with incorrect date" do
      within("#new_event") do
        fill_in 'event_name', with: "NewEvent"
        all('#event_start_date_2i option')[3].select_option
        all('#event_start_date_3i option')[5].select_option
        all('#event_end_date_2i option')[3].select_option
        all('#event_end_date_3i option')[4].select_option
      end
      expect { find("input[name=commit]").click }.not_to change(Event, :count)
    end
  end
end
