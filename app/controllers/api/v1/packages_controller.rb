class Api::V1::PackagesController < ApplicationController
  before_action :authenticate_request!
  load_and_authorize_resource
  before_action :set_package, only: [:show, :update, :destroy]
  respond_to :json

  # GET /api/v1/packages
  def index
    @packages = @packages.includes(:order_packages)
                        .order(created_at: :desc)
    
    @packages = @packages.active if params[:active] == 'true'
    @packages = @packages.by_vehicle_type(params[:vehicle_type]) if params[:vehicle_type].present?
    
    @packages = @packages.page(params[:page]).per(params[:per_page] || 25)
  end

  # GET /api/v1/packages/:id
  def show
  end

  # POST /api/v1/packages
  def create
    @package = Package.new(package_params)
    
    if @package.save
      @message = "Package created successfully"
      render :show, status: :created
    else
      render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/packages/:id
  def update
    if @package.update(package_params)
      @message = "Package updated successfully"
      render :show
    else
      render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/packages/:id
  def destroy
    @package.destroy
    render json: { message: "Package deleted successfully" }
  end

  private

  def set_package
    @package = Package.find(params[:id])
  end

  def package_params
    params.require(:package).permit(:name, :description, :unit_price, :vehicle_type, :active, features: [])
  end
end
