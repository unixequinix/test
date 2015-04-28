class Admins::EntitlementsController < Admins::BaseController

  def index
    @entitlements = Entitlement.all
  end

  def new
    @entitlement = Entitlement.new
  end

  def create
    @entitlement = Entitlement.new(permitted_params)
    if @entitlement.save
      flash[:notice] = "created TODO"
      redirect_to admins_entitlements_url
    else
      flash[:error] = "ERROR TODO"
      render :new
    end
  end

  def edit
    @entitlement = Entitlement.find(params[:id])
  end

  def update
    @entitlement = Entitlement.find(params[:id])
    if @entitlement.update(permitted_params)
      flash[:notice] = "updated TODO"
      redirect_to admins_entitlements_url
    else
      flash[:error] = "ERROR"
      render :edit
    end
  end

  def destroy
    @entitlement = Entitlement.find(params[:id])
    @entitlement.destroy!
    flash[:notice] = "destroyed TODO"
    redirect_to admins_entitlements_url
  end

  private

  def permitted_params
    params.require(:entitlement).permit(:name)
  end

end
