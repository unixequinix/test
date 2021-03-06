module Admins
  module Users
    module Teams
      class DevicesController < Admins::BaseController
        before_action :set_device, only: %i[show edit update destroy]
        before_action :set_team

        def index
          @q = @current_user.glowball? ? Device.all : @current_user&.team&.devices
          @q = @q&.ransack(params[:q])
          @devices = @q.result.includes(:events)
          authorize(@devices)
          @devices = @devices.page(params[:page])
        end

        def show
          @device_events = DeviceTransaction.where(device: @device).includes(:event).group_by(&:event)
        end

        def new
          @device = Device.new(team: @team)
        end

        def edit; end

        def update
          respond_to do |format|
            if @device.update(permitted_params)
              format.json { render json: @device }
              format.html { redirect_to [:admins, current_user, :team] }
            else
              format.json { render status: :unprocessable_entity, json: :no_content }
              format.html { render :edit }
            end
          end
        end

        def create
          @device = Device.new(permitted_params.merge(team_id: @current_user.team.id))
          authorize @device

          respond_to do |format|
            if @current_user.team && @device.save
              format.json { render json: @device }
              format.html { redirect_to [:admins, current_user, @device.team] }
            else
              format.json { render status: :unprocessable_entity, json: :no_content }
              format.html { render :new }
            end
          end
        end

        def destroy
          respond_to do |format|
            if @device.destroy
              format.html { redirect_to admins_user_team_devices_path(current_user), notice: t("alerts.destroyed") }
              format.json { render json: true }
            else
              format.html { redirect_to [:admins, current_user, :team, @device], alert: @device.errors.full_messages.to_sentence }
              format.json { render json: { errors: @device.errors }, status: :unprocessable_entity }
            end
          end
        end

        private

        def set_team
          @team = @current_user.team
        end

        def set_device
          @device = Device.find(params[:id])
          authorize(@device)
        end

        def permitted_params
          params.require(:device).permit(:mac, :asset_tracker, :serie, :serial)
        end
      end
    end
  end
end
