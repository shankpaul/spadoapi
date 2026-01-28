class Api::V1::CustomersController < ApplicationController
  before_action :authenticate_request!
  load_and_authorize_resource
  respond_to :json

  # GET /api/v1/customers
  def index
    @customers = @customers.order(created_at: :desc)
    @customers = apply_filters(@customers)
    @customers = @customers.page(params[:page]).per(params[:per_page] || 25)
  end

  # GET /api/v1/customers/:id
  def show
    render :show, status: :ok
  end

  # POST /api/v1/customers
  def create
    if @customer.save
      @message = 'Customer created successfully'
      render :create, status: :created
    else
      render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/v1/customers/:id
  def update
    if @customer.update(customer_params)
      @message = 'Customer updated successfully'
      render :update, status: :ok
    else
      render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/customers/:id
  def destroy
    @customer.destroy
    render json: { message: 'Customer deleted successfully' }, status: :ok
  end

  private

  def apply_filters(customers)
    # Filter by last_booked_at with time period (e.g., 7d, 1m, 2m, 6m, 1y)
    if params[:last_booked_filter].present?
      time_ago = parse_time_period(params[:last_booked_filter])
      customers = customers.where('last_booked_at >= ?', time_ago) if time_ago
    end

    # Filter by city
    customers = customers.where(city: params[:city]) if params[:city].present?

    # Filter by state
    customers = customers.where(state: params[:state]) if params[:state].present?

    # Filter by has_whatsapp
    customers = customers.where(has_whatsapp: params[:has_whatsapp]) if params[:has_whatsapp].present?

    # Search by name, phone, or email
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      customers = customers.where(
        'name ILIKE ? OR phone ILIKE ? OR email ILIKE ?',
        search_term, search_term, search_term
      )
    end

    customers
  end

  def parse_time_period(period)
    return nil unless period.is_a?(String)

    match = period.match(/^(\d+)(d|m|y)$/)
    return nil unless match

    value = match[1].to_i
    unit = match[2]

    case unit
    when 'd'
      value.days.ago
    when 'm'
      value.months.ago
    when 'y'
      value.years.ago
    else
      nil
    end
  end

  def customer_params
    params.permit(
      :name, :phone, :email, :has_whatsapp, :last_booked_at,
      :address_line1, :address_line2, :area, :city, :district, :state, 
      :latitude, :longitude, :map_link, :last_whatsapp_message_sent_at
    )
  end
end
