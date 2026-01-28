class Api::V1::AddonsController < ApplicationController
  before_action :authenticate_request!
  load_and_authorize_resource
  before_action :set_addon, only: [:show, :update, :destroy]
  respond_to :json

  # GET /api/v1/addons
  def index
    @addons = @addons.includes(:order_addons)
                    .order(created_at: :desc)
    
    @addons = @addons.active if params[:active] == 'true'
    
    @addons = @addons.page(params[:page]).per(params[:per_page] || 25)
  end

  # GET /api/v1/addons/:id
  def show
  end

  # POST /api/v1/addons
  def create
    @addon = Addon.new(addon_params)
    
    if @addon.save
      @message = "Addon created successfully"
      render :show, status: :created
    else
      render json: { errors: @addon.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/addons/:id
  def update
    if @addon.update(addon_params)
      @message = "Addon updated successfully"
      render :show
    else
      render json: { errors: @addon.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/addons/:id
  def destroy
    @addon.destroy
    render json: { message: "Addon deleted successfully" }
  end

  private

  def set_addon
    @addon = Addon.find(params[:id])
  end

  def addon_params
    params.require(:addon).permit(:name, :description, :price, :active)
  end
end
