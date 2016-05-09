require "rails_helper"

RSpec.describe Api::V1::Events::ParametersController, type: :controller do
  let(:admin) { Admin.first || FactoryGirl.create(:admin) }

  describe "GET index" do
    before do
      @event = create(:event)
      @param1 = create(:event_parameter,
                       event: @event,
                       value: "asd123",
                       parameter: Parameter.find_by(category: "device", name: "min_version_apk"))

      @param2 = EventParameter.find_or_create_by(event: @event,
                                                 value: "ultralight_c",
                                                 parameter: Parameter.find_by(category: "gtag",
                                                                              group: "form",
                                                                              name: "gtag_type"))
    end

    context "with authentication" do
      before(:each) do
        http_login(admin.email, admin.access_token)
      end

      it "has a 200 status code" do
        get :index, event_id: @event.id

        expect(response.status).to eq 200
      end

      it "returns all the tickets" do
        get :index, event_id: @event.id

        body = JSON.parse(response.body)
        parameters = body.map { |m| m["value"] }

        expect(parameters).to include(@param1.value)
        expect(parameters).to include(@param2.value)
      end
    end
    context "without authentication" do
      it "has a 401 status code" do
        get :index, event_id: @event.id

        expect(response.status).to eq 401
      end
    end
  end
end
