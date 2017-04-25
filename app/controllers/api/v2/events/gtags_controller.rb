class Api::V2::Events::GtagsController < Api::V2::BaseController
  before_action :set_gtag, only: %i[show update destroy]

  # GET /gtags
  def index
    @gtags = @current_event.gtags
    authorize @gtags

    render json: @gtags, each_serializer: Api::V2::Simple::GtagSerializer
  end

  # GET /gtags/1
  def show
    render json: @gtag
  end

  # POST /gtags
  def create
    @gtag = @current_event.gtags.new(gtag_params)
    authorize @gtag

    if @gtag.save
      render json: @gtag, status: :created, location: @gtag
    else
      render json: @gtag.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /gtags/1
  def update
    if @gtag.update(gtag_params)
      render json: @gtag
    else
      render json: @gtag.errors, status: :unprocessable_entity
    end
  end

  # DELETE /gtags/1
  def destroy
    @gtag.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_gtag
    @gtag = @current_event.gtags.find(params[:id])
    authorize @gtag
  end

  # Only allow a trusted parameter "white list" through.
  def gtag_params
    params.require(:gtag).permit(:tag_uid, :banned, :active, :credits, :refundable_credits, :final_balance, :final_refundable_balance, :customer_id, :redeemed, :ticket_type_id) # rubocop:disable Metrics/LineLength
  end
end