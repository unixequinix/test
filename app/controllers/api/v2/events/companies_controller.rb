module Api::V2
  class Events::CompaniesController < BaseController
    before_action :set_company, only: %i[show update destroy]

    # GET api/v2/events/:event_id/companies
    def index
      @companies = @current_event.companies
      authorize @companies

      render json: @companies
    end

    # GET api/v2/events/:event_id/companies/:id
    def show
      render json: @company, serializer: CompanySerializer
    end

    # POST api/v2/events/:event_id/companies
    def create
      @company = @current_event.companies.new(company_params)
      authorize @company

      if @company.save
        render json: @company, status: :created, location: [:admins, @current_event, @company]
      else
        render json: @company.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT api/v2/events/:event_id/companies/:id
    def update
      if @company.update(company_params)
        render json: @company
      else
        render json: @company.errors, status: :unprocessable_entity
      end
    end

    # DELETE api/v2/events/:event_id/companies/:id
    def destroy
      @company.destroy
      head(:ok)
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_company
      @company = @current_event.companies.find(params[:id])
      authorize @company
    end

    # Only allow a trusted parameter "white list" through.
    def company_params
      params.require(:company).permit(:name)
    end
  end
end
