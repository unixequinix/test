require "rails_helper"

RSpec.describe Companies::Api::V1::GtagsController, type: :controller do
  before(:all) do
    @event = create(:event)
    @ticket_type1 = create(:company_ticket_type, event: @event,
                                                 company: create(:company, event: @event))
    @ticket_type2 = create(:company_ticket_type, event: @event,
                                                 company: create(:company, event: @event))

    5.times { create(:gtag, :with_purchaser, event: @event, company_ticket_type: @ticket_type1) }
    5.times { create(:gtag, :with_purchaser, event: @event, company_ticket_type: @ticket_type2) }
  end

  describe "GET index" do
    context "when authenticated" do
      before(:each) do
        @company = Company.last.name
        http_login(@company, @event.token)
      end

      it "returns 200 status code" do
        get :index, event_id: @event.id

        expect(response.status).to eq(200)
      end

      it "returns only the tickets for that company" do
        get :index, event_id: @event.id

        body = JSON.parse(response.body)
        gtags = body["gtags"].map { |m| m["tag_uid"] }
        expect(gtags).to match_array(Gtag.search_by_company_and_event(@company, @event)
                                         .map(&:tag_uid))
      end
    end

    context "when not authenticated" do
      it "returns a 401 status code" do
        get :index, event_id: @event.id

        expect(response.status).to eq(401)
      end
    end
  end

  describe "GET show" do
    context "when authenticated" do
      before(:each) do
        @company = Company.last.name
        http_login(@company, @event.token)
      end

      context "when the ticket belongs to the company" do
        before(:each) do
          get :show, event_id: @event.id, id: Gtag.last.id
        end

        it "returns a 200 status code" do
          expect(response.status).to eq(200)
        end

        it "returns the correct gtag" do
          body = JSON.parse(response.body)
          expect(body["tag_uid"]).to eq(Gtag.last.tag_uid)
          expect(body["purchaser_email"]).to eq(Gtag.last.purchaser.email)
        end
      end

      context "when the ticket doesn't belong to the company" do
        it "returns a 404 status code" do
          get :show, event_id: @event.id, id: 999
          expect(response.status).to eq(404)
        end
      end
    end

    context "when not authenticated" do
      it "returns a 401 status code" do
        get :show, event_id: @event.id, id: Gtag.last.id

        expect(response.status).to eq(401)
      end
    end
  end

  describe "POST create" do
    context "when authenticated" do
      before(:each) do
        @company = Company.last.name
        http_login(@company, @event.token)
      end

      context "when the request is valid" do
        before(:each) do
          @params = {
            tag_uid: "t4gu1d",
            tag_serial_number: "t4gs3rialnumb3r",
            purchaser_first_name: "Glownet",
            purchaser_last_name: "Glownet",
            purchaser_email: "hi@glownet.com",
            ticket_type_id: CompanyTicketType.last.id
          }
        end

        it "increases the tickets in the database by 1" do
          expect do
            post :create, gtag: @params
          end.to change(Gtag, :count).by(1)
        end

        it "returns a 201 status code" do
          post :create, gtag: @params
          expect(response.status).to eq(201)
        end

        it "returns the created ticket" do
          post :create, gtag: @params

          body = JSON.parse(response.body)
          expect(body["tag_uid"]).to eq(Gtag.last.tag_uid)
          expect(body["purchaser_email"]).to eq(Gtag.last.purchaser.email)
        end
      end

      context "when the request is invalid" do
        it "returns a 400 status code" do
          post :create, gtag: { with: "Invalid request" }
          expect(response.status).to eq(400)
        end
      end
    end

    context "when not authenticated" do
      it "returns a 401 status code" do
        post :create, ticket: { with: "Some data" }
        expect(response.status).to eq(401)
      end
    end
  end

  describe "PATCH update" do
    context "when authenticated" do
      before(:each) do
        @company = Company.last.name
        @gtag = Gtag.last
        http_login(@company, @event.token)
      end

      context "when the request is valid" do
        before(:each) do
          @params = { tag_uid: "n3wtagU1d", purchaser_email: "updated@email.com" }
        end

        it "changes ticket's attributes" do
          put :update, id: @gtag, gtag: @params
          @gtag.reload
          expect(@gtag.tag_uid).to eq("n3wtagU1d".upcase)
          expect(@gtag.purchaser.email).to eq("updated@email.com")
        end

        it "returns a 200 code status" do
          put :update, id: @gtag, gtag: @params
          expect(response.status).to eq(200)
        end

        it "returns the updated ticket" do
          put :update, id: @gtag, gtag: @params
          body = JSON.parse(response.body)
          @gtag.reload
          expect(body["tag_uid"]).to eq(@gtag.tag_uid)
        end
      end

      context "when the request is invalid" do
        it "returns a 400 status code" do
          put :update, id: @gtag, gtag: { tag_uid: nil,
                                          tag_serial_number: "3405sdf234293" }
          expect(response.status).to eq(400)
        end

        it "doesn't change ticket's attributes" do
          put :update, id: @gtag, gtag: { tag_uid: nil,
                                          tag_serial_number: "3405sdf234293" }
          @gtag.reload
          expect(@gtag.tag_serial_number).not_to eq("3405sdf234293")
        end
      end
    end

    context "when not authenticated" do
      it "returns a 401 status code" do
        put :update, id: Gtag.last, gtags: { without: "Authenticate" }
        expect(response.status).to eq(401)
      end
    end
  end
end
