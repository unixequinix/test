require "spec_helper"

RSpec.describe Event, type: :model do
  subject { build(:event) }

  describe ".valid_app_version?" do
    before { subject.app_version = "1.0.0.0" }

    it "returns true if version is higher" do
      expect(subject.valid_app_version?("1.0.0.1")).to be_truthy
    end

    it "returns true if version matches" do
      expect(subject.valid_app_version?("1.0.0.0")).to be_truthy
    end

    it "returns false if version is lower" do
      expect(subject.valid_app_version?("0.9.9.9")).to be_falsey
    end

    it "handles 3 digit versions with valid app version" do
      expect(subject.valid_app_version?("1.0.1")).to be_truthy
    end

    it "handles 3 digit versions with invalid app version" do
      expect(subject.valid_app_version?("0.9.1")).to be_falsey
    end

    it "handles pre-release versions" do
      expect(subject.valid_app_version?("1.0.1-beta")).to be_truthy
    end

    it "handles pre-release of the same version" do
      expect(subject.valid_app_version?("1.0.0.0-DEBUG")).to be_truthy
    end

    it "always returns true if the app_version is all" do
      subject.app_version = "all"
      expect(subject.valid_app_version?("notaversion")).to be_truthy
      expect(subject.valid_app_version?(nil)).to be_truthy
      expect(subject.valid_app_version?([])).to be_truthy
    end
  end

  describe ".eventbrite?" do
    it "returns true if the event has eventbrite_token and eventbrite_event" do
      expect(subject).not_to be_eventbrite
      subject.eventbrite_token = "test"
      expect(subject).not_to be_eventbrite
      subject.eventbrite_event = "test"
      expect(subject).to be_eventbrite
    end
  end

  describe ".credit_price" do
    it "returns the event credit value" do
      subject.save
      subject.create_credit!(value: 1, name: "CR")
      expect(subject.credit_price).to eq(subject.credit.value)
    end
  end

  describe ".active?" do
    it "returns true if the event is launched, started or finished" do
      subject.state = "closed"
      expect(subject).not_to be_active
      subject.state = "created"
      expect(subject).not_to be_active

      subject.state = "launched"
      expect(subject).to be_active
      subject.state = "started"
      expect(subject).to be_active
      subject.state = "finished"
      expect(subject).to be_active
    end
  end
end
