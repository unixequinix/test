class Admins::Events::PaymentsController < Admins::Events::PaymentsBaseController
  before_filter :set_presenter, only: [:index, :search]

  def index
    respond_to do |format|
      format.html
      format.csv { send_data Csv::CsvExporter.to_csv(@fetcher.payments) }
    end
  end

  def search
    render :index
  end

  def show
    @payment = @fetcher.payments.find(params[:id])
  end

  private

  def set_presenter
    @list_model_presenter = ListModelPresenter.new(
      model_name: "Payment".constantize.model_name,
      fetcher: @fetcher.payments,
      search_query: params[:q],
      page: params[:page],
      include_for_all_items: [:order],
      context: view_context
    )
  end
end
