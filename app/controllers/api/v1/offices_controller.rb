class Api::V1::OfficesController < ApplicationController
  before_action :authenticate_request!
  before_action :set_office, only: [:show, :update, :destroy, :activate, :deactivate]
  load_and_authorize_resource

  # GET /api/v1/offices
  def index
    @offices = Office.includes(:users).ordered
    @offices = @offices.active if params[:active_only] == 'true'
    
    render json: {
      offices: @offices.map do |office|
        {
          id: office.id,
          name: office.name,
          latitude: office.latitude,
          longitude: office.longitude,
          coordinates: office.coordinates,
          active: office.active,
          user_count: office.users.count,
          created_at: office.created_at,
          updated_at: office.updated_at
        }
      end
    }, status: :ok
  end

  # GET /api/v1/offices/:id
  def show
    render json: {
      office: {
        id: @office.id,
        name: @office.name,
        latitude: @office.latitude,
        longitude: @office.longitude,
        coordinates: @office.coordinates,
        active: @office.active,
        user_count: @office.users.count,
        users: @office.users.map do |user|
          {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          }
        end,
        created_at: @office.created_at,
        updated_at: @office.updated_at
      }
    }, status: :ok
  end

  # POST /api/v1/offices
  def create
    @office = Office.new(office_params)

    if @office.save
      render json: {
        message: 'Office created successfully',
        office: {
          id: @office.id,
          name: @office.name,
          latitude: @office.latitude,
          longitude: @office.longitude,
          coordinates: @office.coordinates,
          active: @office.active,
          user_count: 0,
          created_at: @office.created_at,
          updated_at: @office.updated_at
        }
      }, status: :created
    else
      render json: { errors: @office.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/v1/offices/:id
  def update
    if @office.update(office_params)
      render json: {
        message: 'Office updated successfully',
        office: {
          id: @office.id,
          name: @office.name,
          latitude: @office.latitude,
          longitude: @office.longitude,
          coordinates: @office.coordinates,
          active: @office.active,
          user_count: @office.users.count,
          created_at: @office.created_at,
          updated_at: @office.updated_at
        }
      }, status: :ok
    else
      render json: { errors: @office.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/offices/:id
  def destroy
    if @office.users.any?
      render json: { 
        error: "Cannot delete office with assigned users. Please reassign #{@office.users.count} user(s) first." 
      }, status: :unprocessable_entity
    else
      @office.destroy
      render json: { message: 'Office deleted successfully' }, status: :ok
    end
  end

  # POST /api/v1/offices/:id/activate
  def activate
    @office.activate!
    render json: { 
      message: 'Office activated successfully',
      office: {
        id: @office.id,
        name: @office.name,
        active: @office.active
      }
    }, status: :ok
  end

  # POST /api/v1/offices/:id/deactivate
  def deactivate
    @office.deactivate!
    render json: { 
      message: 'Office deactivated successfully',
      office: {
        id: @office.id,
        name: @office.name,
        active: @office.active
      }
    }, status: :ok
  end

  private

  def set_office
    @office = Office.find(params[:id])
  end

  def office_params
    params.require(:office).permit(:name, :latitude, :longitude, :active)
  end
end
