class Api::V2::Events::StationsController < Api::V2::BaseController
  before_action :set_station, only: %i[show update destroy add_product remove_product update_product]

  # GET api/v2/events/:event_id/stations
  def index
    @stations = @current_event.stations
    authorize @stations

    paginate json: @stations
  end

  # GET api/v2/events/:event_id/stations/:id
  def show
    render json: @station
  end

  # POST api/v2/events/:event_id/stations
  def create
    @station = @current_event.stations.new(station_params)
    authorize @station

    if @station.save
      render json: @station, status: :created, location: [:admins, @current_event, @station]
    else
      render json: @station.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT api/v2/events/:event_id/stations/:id
  def update
    if @station.update(station_params)
      render json: @station
    else
      render json: @station.errors, status: :unprocessable_entity
    end
  end

  # DELETE api/v2/events/:event_id/stations/:id
  def destroy
    @station.destroy
    head(:ok)
  end

  def add_product
    @station_product = @station.station_products.create!(price: product_params[:price], product_id: product_params[:id])
    authorize @station

    if @station_product
      render json: @station_product
    else
      render json: @station_product.errors, status: :unprocessable_entity
    end
  end

  def remove_product
    @station.station_products.find_by(product_id: product_params[:id]).destroy
  end

  def update_product
    @station_product = @station.station_products.find_by(product_id: product_params[:id])
    authorize @station
    atts = product_params.slice(:price, :position)
    if @station_product.update(atts)
      render json: @station_product
    else
      render json: @station_product.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_station
    @station = @current_event.stations.find(params[:id])
    authorize @station
  end

  # Only allow a trusted parameter "white list" through.
  def station_params
    params.require(:station).permit(:name, :location, :category, :reporting_category, :address, :registration_num, :official_name, :hidden)
  end

  def product_params
    params.require(:product).permit(:id, :price, :position)
  end
end
