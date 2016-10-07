class Admins::Events::AccessesController < Admins::Events::BaseController
  before_action :set_access, except: [:index, :new, :create]

  def index
    set_presenter
  end

  def new
    @access = Access.new
    @access.build_catalog_item
    @access.build_entitlement
  end

  def create
    @access = Access.new(permitted_params)
    if @access.save
      flash[:notice] = I18n.t("alerts.created")
      redirect_to admins_event_accesses_url
    else
      flash.now[:error] = @access.errors.full_messages.join(". ")
      render :new
    end
  end

  def update
    if @access.update(permitted_params)
      flash[:notice] = I18n.t("alerts.updated")
      redirect_to admins_event_accesses_url
    else
      flash.now[:error] = @access.errors.full_messages.join(". ")
      render :edit
    end
  end

  def destroy
    if @access.destroy
      flash[:notice] = I18n.t("alerts.destroyed")
      redirect_to admins_event_accesses_url
    else
      flash.now[:error] = I18n.t("errors.messages.catalog_item_dependent")
      set_presenter
      render :index
    end
  end

  def create_credential
    @access.catalog_item.create_credential_type if @access.catalog_item.credential_type.blank?
    redirect_to admins_event_accesses_url
  end

  def destroy_credential
    @access.catalog_item.credential_type.destroy if @access.catalog_item.credential_type.present?
    redirect_to admins_event_accesses_url
  end

  private

  def set_access
    @access = current_event.accesses.find(params[:id])
  end

  def set_presenter
    @list_model_presenter = ListModelPresenter.new(
      model_name: "Access".constantize.model_name,
      fetcher: current_event.accesses,
      search_query: params[:q],
      page: params[:page],
      include_for_all_items: [:entitlement, catalog_item: :credential_type],
      context: view_context
    )
  end

  def permitted_params
    ci_atts = [:id, :event_id, :name, :description, :initial_amount,
               :step, :max_purchasable, :min_purchasable]
    ent_atts = [:id, :memory_length, :mode, :event_id]
    params.require(:access).permit(catalog_item_attributes: ci_atts,
                                   entitlement_attributes: ent_atts)
  end
end