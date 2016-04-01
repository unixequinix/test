require "rails_helper"

RSpec.describe Api::V1::Events::StationsController, type: :controller do
  let(:event) { Event.first || create(:event) }
  let(:admin) { Admin.first || create(:admin) }

  describe "GET index" do
    context "with authentication" do
      before(:each) do
        http_login(admin.email, admin.access_token)
      end

      it "has a 200 status code" do
        get :index, event_id: event.id
        expect(response.status).to eq(200)
      end

      context "when the station is a box office" do
        before do
          group = create(:station_group, name: "access")
          type = create(:station_type, name: "box_office", station_group: group)
          @station = create(:station, station_type: type, event: event)
          @station.station_catalog_items
            .new(price: rand(1.0...20.0),
                 catalog_item_id: create(:access_catalog_item, event: event).id,
                 station_parameter_attributes: { station_id: @station.id }).save
        end

        it "returns all the box office stations" do
          get :index, event_id: event.id
          stations = JSON.parse(response.body).first["stations"].map { |m| m["id"] }
          expect(stations).to eq([@station.id])
        end

        it "returns the catalog items for each box office" do
          get :index, event_id: event.id
          s = JSON.parse(response.body).first["stations"].first
          s_ws_items = s["catalog"].map { |m| m["catalogable_id"] }
          s_db_items = @station.station_catalog_items.map { |m| m.catalog_item.catalogable_id }

          expect(s).to have_key("catalog")
          expect(s_ws_items).to eq(s_db_items)
        end
      end

      context "when the station is a point of sales" do
        before do
          group = create(:station_group, name: "monetary")
          type = create(:station_type, name: "pos", station_group: group)
          @station = create(:station, station_type: type, event: event)
          @station.station_products
            .new(price: rand(1.0...20.0),
                 product: create(:product, event: event),
                 station_parameter_attributes: { station_id: @station.id }).save
        end

        it "returns all the pos stations" do
          get :index, event_id: event.id
          stations = JSON.parse(response.body).first["stations"].map { |m| m["id"] }
          expect(stations).to eq([@station.id])
        end

        it "returns the catalog items for each pos" do
          get :index, event_id: event.id
          s = JSON.parse(response.body).first["stations"].first
          expect(s).to have_key("products")

          s_ws_items = s["products"]
          s_db_items = @station.station_products.map do |m|
            { "product_id" => m["product_id"], "price" => m["price"] }
          end
          expect(s_ws_items).to eq(s_db_items)
        end
      end
    end
    context "without authentication" do
      it "has a 401 status code" do
        get :index, event_id: event.id

        expect(response.status).to eq(401)
      end
    end
  end
end
