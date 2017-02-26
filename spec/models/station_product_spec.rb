require "spec_helper"

RSpec.describe StationProduct, type: :model do
  subject { create(:station_product) }

  describe "station touch" do
    before(:each) { subject.save }

    it "resets the station updated_at field" do
      expect { subject.update!(price: 10) }.to change(subject.station, :updated_at)
    end
  end
end
