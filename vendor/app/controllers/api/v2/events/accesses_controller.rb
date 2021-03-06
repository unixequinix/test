module Api::V2
  class Events::AccessesController < BaseController
    before_action :set_access, only: %i[show update destroy]

    # GET api/v2/events/:event_id/accesses
    def index
      @accesses = @current_event.accesses
      authorize @accesses

      paginate json: @accesses
    end

    # GET api/v2/events/:event_id/accesses/:id
    def show
      render json: @access, serializer: AccessSerializer
    end

    # POST api/v2/events/:event_id/accesses
    def create
      @access = @current_event.accesses.new(access_params)
      authorize @access

      if @access.save
        render json: @access, status: :created, location: [:admins, @current_event, @access]
      else
        render json: @access.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT api/v2/events/:event_id/accesses/:id
    def update
      if @access.update(access_params)
        render json: @access
      else
        render json: @access.errors, status: :unprocessable_entity
      end
    end

    # DELETE api/v2/events/:event_id/accesses/:id
    def destroy
      @access.destroy!
      head(:ok)
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_access
      @access = @current_event.accesses.find(params[:id])
      authorize @access
    end

    # Only allow a trusted parameter "white list" through.
    def access_params
      params.require(:access).permit(:name, :mode)
    end
  end
end
