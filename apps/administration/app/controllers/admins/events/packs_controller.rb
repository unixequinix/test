class Admins::Events::PacksController < Admins::Events::BaseController
  def index
    set_presenter
  end

  def new
    @pack = Pack.new
    @pack.build_catalog_item
    @catalog_items_collection = @fetcher.catalog_items.where.not(catalogable_type: "Pack")
  end

  def create
    @pack = Pack.new(permitted_params)
    if @pack.save
      flash[:notice] = I18n.t("alerts.created")
      redirect_to admins_event_packs_url
    else
      @catalog_items_collection = @fetcher.catalog_items.where.not(catalogable_type: "Pack")
      flash.now[:error] = @pack.errors.full_messages.join(". ")
      render :new
    end
  end

  def edit
    @pack = @fetcher.packs.find(params[:id])
    @catalog_items_collection = @fetcher.catalog_items.where.not(catalogable_type: "Pack")
  end

  def update
    @pack = @fetcher.packs.find(params[:id])
    if @pack.update(permitted_params)
      flash[:notice] = I18n.t("alerts.updated")
      redirect_to admins_event_packs_url
    else
      @catalog_items_collection = @fetcher.catalog_items.where.not(catalogable_type: "Pack")
      flash.now[:error] = @pack.errors.full_messages.join(". ")
      render :edit
    end
  end

  def destroy
    @pack = @fetcher.packs.find(params[:id])
    @pack.destroy!
    flash[:notice] = I18n.t("alerts.destroyed")
    redirect_to admins_event_packs_url
  end

  private

  def set_presenter
    @list_model_presenter = ListModelPresenter.new(
      model_name: "Pack".constantize.model_name,
      fetcher: @fetcher.packs,
      search_query: params[:q],
      page: params[:page],
      context: view_context,
      include_for_all_items: [:catalog_item]
    )
  end

def permitted_params
    params.require(:pack).permit(catalog_item_attributes: [
                                                           :id,
                                                           :event_id,
                                                           :name,
                                                           :description,
                                                           :initial_amount,
                                                           :step,
                                                           :max_purchasable,
                                                           :min_purchasable
                                                          ],
                                 pack_catalog_items_attributes: [
                                  :id,
                                  :catalog_item_id,
                                  :amount,
                                  :_destroy
                                 ]
                                )
  end
end
