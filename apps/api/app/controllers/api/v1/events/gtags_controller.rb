class Api::V1::Events::GtagsController < Api::V1::Events::BaseController
  def index
    render json: @fetcher.gtags, each_serializer: Api::V1::GtagSerializer
  end

  def show
    @gtag = @fetcher.gtags.find_by(id: params[:id])

    render(status: :not_found, json: :not_found) && return if @gtag.nil?
    render json: @gtag, serializer: Api::V1::GtagSerializer
  end
end
