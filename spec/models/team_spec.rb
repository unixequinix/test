require "rails_helper"

RSpec.describe Team, type: :model do
  subject { build(:team) }

  it "has a valid factory" do
    expect(subject).to be_valid
  end

  it "must have a valid name" do
    subject.name = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:name]).to include("can't be blank")
  end

  it "has no users on initilization" do
    expect(subject.users).to be_empty
  end

  it "is not valid without users" do
    subject.team_invitations = []
    expect(subject).not_to be_valid
  end

  it "can have many users" do
    subject = build(:team, :with_users)
    expect(subject.users).not_to be_empty
  end

  it "can have users as leaders" do
    leader = create(:team_invitation, team: subject, user: create(:user), leader: true).user
    expect(subject.leaders).to include(leader)
  end

  it "should not be possible to have leader as guests team" do
    leader = create(:team_invitation, team: subject, user: create(:user), leader: true)
    expect(subject.guests).not_to include(leader)
  end

  it "should return all leaders" do
    expect(subject.leaders).to eq(subject.users)
  end

  it "should return all guests" do
    guest = create(:team_invitation, user: create(:user), team: subject).user
    expect(subject.guests).to eq([guest])
  end

  describe "devices flow" do
    before do
      subject.save!
      @event1 = create(:event, open_devices_api: true, state: 'launched')
      @event2 = create(:event, open_devices_api: false, state: 'launched')
      devices = create_list(:device, 3, team: subject, serie: 'serie1')
      create(:device_registration, device: devices.first, event: @event1, allowed: true)
      create(:device_registration, device: devices.last, event: @event2, allowed: false)
    end

    it "should return devices series" do
      expect(subject.devices_series).to eq(['serie1'])
    end

    it "should return all associated events" do
      create(:event_registration, event: @event1, user: subject.users.first)
      create(:event_registration, event: @event2, user: subject.users.first)
      expect(subject.events).to match_array([@event2, @event1])
    end

    it "should return empty associated events" do
      create(:event_registration, event: @event2, user: subject.users.first)
      expect(subject.events.live).to eq([])
    end

    it "should return associated events" do
      create(:event_registration, event: @event1, user: subject.users.first)
      expect(subject.events.live).to eq([@event1])
    end

    it "is unable to destroy team with devices attached" do
      expect { subject.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end
end
