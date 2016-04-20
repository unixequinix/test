require "rails_helper"

RSpec.describe Api::V1::EventsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:db_events) { Event.all }

  describe "GET index" do
    context "with authentication" do
      before do
        create_list(:event, 2)
        http_login(admin.email, admin.access_token)
        get :index
        @body = JSON.parse(response.body)
      end

      it "has a 200 status code" do
        get :index
        expect(response.status).to eq(200)
      end

      it "returns all the events" do
        event_names = @body.map { |m| m["id"] }
        expect(event_names).to eq(db_events.map(&:id))
      end

      it "returns the necessary keys" do
        @body.map do |event|
          expect(event.keys).to eq(%w(id name description start_date end_date))
        end
      end

      it "returns the correct data" do
        @body.each_with_index do |event, i|
          event_atts = {
            id: db_events[i].id,
            name: db_events[i].name,
            description: db_events[i].description,
            start_date: db_events[i].start_date,
            end_date: db_events[i].end_date
          }
          expect(event_atts.as_json).to eq(event)
        end
      end
    end
    context "without authentication" do
      it "has a 401 status code" do
        get :index
        expect(response.status).to eq(401)
      end
    end
  end
end
