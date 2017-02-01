class Admins::Events::PacksController < Admins::Events::BaseController
  before_action :set_pack, except: [:index, :new, :create]
  before_action :set_catalog_items, except: [:index, :destroy]

  def index
    @packs = @current_event.packs.includes(:catalog_items)
    authorize @packs
    @packs = @packs.page(params[:page])
  end

  def new
    @pack = @current_event.packs.new
    authorize @pack
  end

  def create
    @pack = @current_event.packs.new(permitted_params)
    authorize @pack

    if @pack.save
      redirect_to admins_event_packs_path, notice: t("alerts.created")
    else
      flash.now[:error] = t("alerts.error")
      render :new
    end
  end

  def update
    if @pack.update(permitted_params)

      # TODO: find out why the fuck are these lines necessary when rails supposedly does this by itself. (jake)
      @pack.pack_catalog_items.map(&:save)
      @pack.pack_catalog_items.select(&:marked_for_destruction?).map(&:destroy)

      redirect_to admins_event_packs_path, notice: t("alerts.updated")
    else
      flash.now[:error] = t("alerts.error")
      render :edit
    end
  end

  def destroy
    respond_to do |format|
      if @pack.destroy
        format.html { redirect_to admins_event_packs_path, notice: t("alerts.destroyed") }
        format.json { render json: true }
      else
        format.html { redirect_to [:admins, @current_event, @pack], error: @pack.errors.full_messages.to_sentence }
        format.json { render json: { errors: @pack.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_pack
    @pack = @current_event.packs.find(params[:id])
    authorize @pack
  end

  def set_catalog_items
    @catalog_items_collection = @current_event.catalog_items.not_user_flags.not_packs
  end

  def permitted_params
    params.require(:pack).permit(:name, :initial_amount, :step, :max_purchasable, :min_purchasable,
                                 pack_catalog_items_attributes: [:id, :catalog_item_id, :amount, :_destroy])
  end
end
