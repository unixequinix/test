class Admins::Events::CompaniesController < Admins::Events::BaseController
  def index
    set_presenter
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(permitted_params)
    if @company.save
      flash[:notice] = I18n.t('alerts.created')
      redirect_to admins_event_companies_url
    else
      flash[:error] = @company.errors.full_messages.join('. ')
      render :new
    end
  end

  def edit
    @company = @fetcher.companies.find(params[:id])
  end

  def update
    @company = @fetcher.companies.find(params[:id])
    if @company.update(permitted_params)
      flash[:notice] = I18n.t('alerts.updated')
      redirect_to admins_event_companies_url
    else
      flash[:error] = @company.errors.full_messages.join('. ')
      render :edit
    end
  end

  def destroy
    @company = @fetcher.companies.find(params[:id])
    @company.destroy!
    flash[:notice] = I18n.t('alerts.destroyed')
    redirect_to admins_event_companies_url
  end

  private

  def set_presenter
    @list_model_presenter = ListModelPresenter.new(
      model_name: 'Company'.constantize.model_name,
      fetcher: @fetcher.companies,
      search_query: params[:q],
      page: params[:page],
      include_for_all_items: [],
      context: view_context
    )
  end

  def permitted_params
    params.require(:company).permit(:name, :event_id)
  end
end
