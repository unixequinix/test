require "rails_helper"

RSpec.feature "Ticket assignation", type: :feature do
  context "with account signed in" do
    before :all do
      @event = build(:event, features: 3, aasm_state: "launched")
      @customer = build(:customer, event: @event)
      create(:profile, customer: @customer, event: @event)
      login_as(@customer, scope: :customer)
    end

    describe "a customer " do
      before :each do
        @ticket = create(:ticket, :with_purchaser, event: @event)
      end

      it "should be able to assign a ticket" do
        visit "/#{@event.slug}/ticket_assignments/new"
        within("form") do
          fill_in(t("admissions.placeholders.ticket_code"), with: @ticket.code)
        end
        click_button(t("admissions.button"))
        expect(current_path).to eq("/#{@event.slug}")
        expect(page.body).to include(@ticket.code)
      end
    end
  end
end
