class Api::V1::UsersController < ApplicationController
  before_action :authenticate_request!
  load_and_authorize_resource
  respond_to :json

  # POST /api/v1/users
  def create
    if @user.save
      @message = 'User created successfully'
      render :update, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/users
  def index
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.order(created_at: :desc)
    render :index, status: :ok
  end

  # GET /api/v1/users/:id
  def show
    render :show, status: :ok
  end

  # PUT/PATCH /api/v1/users/:id
  def update
    if @user.update(user_update_params)
      @message = 'User updated successfully'
      render :update, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/:id
  def destroy
    @user.destroy
    render json: { message: 'User deleted successfully' }, status: :ok
  end

  # POST /api/v1/users/:id/lock
  def lock
    @user.lock_account!
    render json: { message: 'User account locked successfully' }, status: :ok
  end

  # POST /api/v1/users/:id/unlock
  def unlock
    @user.unlock_account!
    render json: { message: 'User account unlocked successfully' }, status: :ok
  end

  # PUT /api/v1/users/:id/role
  def update_role
    if @user.update(role: params[:role])
      @message = 'User role updated successfully'
      render :update, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_update_params
    if current_user.admin?
      params.permit(:name, :email, :role, :phone, :address, :employee_number, :home_latitude, :home_longitude, :office_id, :avatar)
    else
      params.permit(:name, :email, :phone, :address, :employee_number, :home_latitude, :home_longitude, :office_id, :avatar)
    end
  end

  def user_create_params
    params.permit(:name, :email, :password, :password_confirmation, :role, :phone, :address, :employee_number, :home_latitude, :home_longitude, :office_id, :avatar)
  end
end
