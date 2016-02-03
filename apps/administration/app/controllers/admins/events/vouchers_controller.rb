class Admins::Events::VouchersController < Admins::Events::BaseController
  def index
    set_presenter
  end

  def new
    @voucher = Voucher.new
    @voucher.build_preevent_item
  end

  def create
    @voucher = Voucher.new(permitted_params)
    if @voucher.save
      flash[:notice] = I18n.t("alerts.created")
      redirect_to admins_event_vouchers_url
    else
      flash.now[:error] = @voucher.errors.full_messages.join(". ")
      render :new
    end
  end

  def edit
    @voucher = @fetcher.vouchers.find(params[:id])
  end

  def update
    @voucher = @fetcher.vouchers.find(params[:id])
    binding.pry
    if @voucher.update_attributes(permitted_params)
      flash[:notice] = I18n.t("alerts.updated")
      redirect_to admins_event_vouchers_url
    else
      flash.now[:error] = @voucher.errors.full_messages.join(". ")
      render :edit
    end
  end

  def destroy
    @voucher = @fetcher.vouchers.find(params[:id])
    if @voucher.destroy
      flash[:notice] = I18n.t("alerts.destroyed")
      redirect_to admins_event_vouchers_url
    else
      flash.now[:error] = I18n.t("errors.messages.preevent_item_dependent")
      set_presenter
      render :index
    end
  end

  private

  def set_presenter
    @list_model_presenter = ListModelPresenter.new(
      model_name: "Voucher".constantize.model_name,
      fetcher: @fetcher.vouchers,
      search_query: params[:q],
      page: params[:page],
      include_for_all_items: [:preevent_item],
      context: view_context
    )
  end

  def permitted_params
    params.require(:voucher).permit(:counter,
                                    preevent_item_attributes: [
                                      :id,
                                      :event_id,
                                      :name,
                                      :description
                                    ]
                                   )
  end
end
