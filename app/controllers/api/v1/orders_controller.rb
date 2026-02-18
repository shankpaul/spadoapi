class Api::V1::OrdersController < ApplicationController
  before_action :authenticate_request!
  load_and_authorize_resource except: [:create]
  before_action :set_order, only: [:show, :update, :destroy, :assign, :reassign, :update_status, :cancel, :feedback, :reassignments, :timeline, :track_travel]
  respond_to :json

  # GET /api/v1/orders
  def index
    # Filter by assigned agent if user is an agent
    @orders = @orders.assigned_to(current_user.id) if current_user.agent?
    
    @orders = apply_filters(@orders)
    @orders = @orders.with_associations
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(params[:per_page] || 25)
  end

  # GET /api/v1/orders/:id
  def show
    @order = Order.with_associations.find(@order.id)
  end

  # POST /api/v1/orders
  def create
    authorize! :create, Order
    
    service = Orders::CreationService.new(order_create_params, current_user)
    @order = service.create

    if service.success?
      # Auto-confirm order if status is confirmed
      base_params = params[:order] || params
      if (base_params[:status] || params[:status]) == 'confirmed'
        @order.confirm_booking! if @order.may_confirm_booking?
      end
      
      # Queue background jobs for image processing
      if params[:before_images].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'before_images')
      end
      
      if params[:after_images].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'after_images')
      end
      
      if params[:customer_signature].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'customer_signature')
      end
      
      if params[:payment_proof].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'payment_proof')
      end
      
      @message = "Order created successfully"
      render :show, status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/orders/:id
  def update
    update_params = order_update_params
    
    # Handle nested address hash if present
    if params[:order].present? && params[:order][:address].present?
      address = params[:order][:address]
      update_params[:area] = address[:area] if address[:area].present?
      update_params[:city] = address[:city] if address[:city].present?
      update_params[:district] = address[:district] if address[:district].present?
      update_params[:state] = address[:state] if address[:state].present?
      update_params[:map_link] = address[:map_link] if address[:map_link].present?
      update_params[:latitude] = address[:latitude] if address[:latitude].present?
      update_params[:longitude] = address[:longitude] if address[:longitude].present?
    end
    
    # Handle booking time parsing
    if update_params[:booking_date].present?
      booking_date = update_params[:booking_date]
      
      if update_params[:booking_time_from].present? && update_params[:booking_time_from].is_a?(String)
        update_params[:booking_time_from] = parse_time_with_date(update_params[:booking_time_from], booking_date)
      end
      
      if update_params[:booking_time_to].present? && update_params[:booking_time_to].is_a?(String)
        update_params[:booking_time_to] = parse_time_with_date(update_params[:booking_time_to], booking_date)
      end
    end
    
    # Handle packages and addons update
    packages_data = nil
    addons_data = nil
    
    if params[:packages].present?
      packages_data = params[:packages].map do |pkg|
        pkg_hash = {
          package_id: pkg[:package_id],
          quantity: pkg[:quantity],
          price: pkg[:unit_price] || pkg[:price],
          vehicle_type: pkg[:vehicle_type].to_s.downcase,
          notes: pkg[:notes]
        }
        
        # Handle discount - include if not nil (allows 0)
        pkg_hash[:discount] = pkg[:discount_value] || pkg[:discount] unless (pkg[:discount_value] || pkg[:discount]).nil?
        
        pkg_hash.compact
      end
    end
    
    if params[:addons].present?
      addons_data = params[:addons].map do |addon|
        addon_hash = {
          addon_id: addon[:addon_id],
          quantity: addon[:quantity],
          price: addon[:unit_price] || addon[:price]
        }
        
        # Handle discount - include if not nil (allows 0)
        addon_hash[:discount] = addon[:discount_value] || addon[:discount] unless (addon[:discount_value] || addon[:discount]).nil?
        
        addon_hash.compact
      end
    end
    
    # Use transaction to ensure all updates happen together
    ActiveRecord::Base.transaction do
      # Update basic order fields
      @order.update!(update_params)
      
      # Update packages if provided
      if packages_data.present?
        # Delete existing packages
        @order.order_packages.destroy_all
        
        # Create new packages
        packages_data.each do |pkg_data|
          @order.order_packages.create!(pkg_data)
        end
      end
      
      # Update addons if provided
      if addons_data.present?
        # Delete existing addons
        @order.order_addons.destroy_all
        
        # Create new addons
        addons_data.each do |addon_data|
          @order.order_addons.create!(addon_data)
        end
      end
      
      # Recalculate totals if packages or addons were updated
      if packages_data.present? || addons_data.present? || should_recalculate?
        Orders::CalculationService.call(@order)
      end
      
      # Queue background jobs for image processing
      if params[:before_images].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'before_images')
      end
      
      if params[:after_images].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'after_images')
      end
      
      if params[:customer_signature].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'customer_signature')
      end
      
      if params[:payment_proof].present?
        ProcessOrderImagesJob.perform_later(@order.id, 'payment_proof')
      end
      
      # Auto-calculate tip if received_amount is provided
      if update_params[:received_amount].present? && @order.total_price.present?
        calculated_tip = @order.calculate_tip
        @order.update_column(:tip, calculated_tip) if calculated_tip > 0
      end
    end
    
    @message = "Order updated successfully"
    render :show
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  # DELETE /api/v1/orders/:id
  def destroy
    @order.destroy
    render json: { message: "Order deleted successfully" }
  end

  # POST /api/v1/orders/:id/assign
  def assign
    service = Orders::AssignmentService.new(@order, params[:agent_id], current_user, params[:notes])
    result = service.assign

    if service.success?
      @order = result
      @message = "Order assigned successfully"
      render :show
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/orders/:id/reassign
  def reassign
    agent_id = params[:agent_id]
    
    # If agent_id is nil or empty, unassign the order
    if agent_id.blank?
      @order.update(assigned_to_id: nil)
      @message = "Order unassigned successfully"
      render :show
    else
      service = Orders::AssignmentService.new(@order, agent_id, current_user, params[:notes])
      result = service.assign

      if service.success?
        @order = result
        @message = "Order reassigned successfully"
        render :show
      else
        render json: { errors: service.errors }, status: :unprocessable_entity
      end
    end
  end

  # POST /api/v1/orders/:id/update_status
  def update_status
    service = Orders::StatusUpdateService.new(
      @order,
      params[:status],
      current_user,
      status_params
    )
    
    result = service.update_status

    if service.success?
      @order = result
      @message = "Order status updated successfully"
      render :show
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/orders/:id/cancel
  def cancel
    unless params[:cancel_reason].present?
      return render json: { errors: ["Cancel reason is required"] }, status: :unprocessable_entity
    end

    service = Orders::StatusUpdateService.new(
      @order,
      :cancelled,
      current_user,
      { cancel_reason: params[:cancel_reason] }
    )
    
    result = service.update_status

    if service.success?
      @order = result
      @message = "Order cancelled successfully"
      render :show
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/orders/:id/feedback
  def feedback
    unless @order.can_add_feedback?
      return render json: { errors: ["Feedback can only be added to completed orders"] }, status: :unprocessable_entity
    end

    if @order.update(feedback_params.merge(feedback_submitted_at: Time.current))
      @message = "Feedback added successfully"
      render :show
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/orders/calendar
  def calendar
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 30.days
    
    @orders = @orders.where(booking_date: start_date..end_date)
                     .where.not(status: :cancelled)
                     .includes(:customer, :assigned_to)
                     .order(booking_date: :asc, booking_time_from: :asc)
    
    render :index
  end

  # GET /api/v1/orders/:id/reassignments
  def reassignments
    @assignment_histories = @order.assignment_histories
                                   .includes(:assigned_to, :assigned_by)
                                   .order(assigned_at: :desc)
    
    render json: {
      order_id: @order.id,
      order_number: @order.order_number,
      current_agent: @order.assigned_to&.name,
      reassignments: @assignment_histories.map do |history|
        {
          id: history.id,
          assigned_to: history.assigned_to.name,
          assigned_by: history.assigned_by&.name,
          assigned_at: history.assigned_at,
          status: history.status,
          notes: history.notes
        }
      end
    }
  end

  # GET /api/v1/orders/:id/timeline
  def timeline
    @status_logs = @order.order_status_logs
                         .includes(:changed_by)
                         .order(changed_at: :asc)
    
    timeline_events = @status_logs.map do |log|
      {
        id: log.id,
        event_type: 'status_change',
        from_status: log.from_status,
        to_status: log.to_status,
        changed_by: log.changed_by&.name,
        changed_at: log.changed_at,
        description: "Status changed from #{log.from_status} to #{log.to_status}"
      }
    end
    
    # Add assignment history to timeline
    @order.assignment_histories.includes(:assigned_to, :assigned_by).each do |history|
      timeline_events << {
        id: "assignment_#{history.id}",
        event_type: 'assignment',
        assigned_to: history.assigned_to.name,
        assigned_by: history.assigned_by&.name,
        changed_at: history.assigned_at,
        description: "Assigned to #{history.assigned_to.name}",
        notes: history.notes
      }
    end
    
    # Sort all events by timestamp
    timeline_events.sort_by! { |event| event[:changed_at] }
    
    render json: {
      order_id: @order.id,
      order_number: @order.order_number,
      current_status: @order.status,
      timeline: timeline_events
    }
  end

  # POST /api/v1/orders/:id/track_travel
  # Track agent journey to/from customer location
  def track_travel
    # Validate required parameters
    unless params[:from_latitude].present? && params[:from_longitude].present?
      return render json: { 
        error: 'Starting location (from_latitude and from_longitude) is required' 
      }, status: :unprocessable_entity
    end

    unless params[:to_latitude].present? && params[:to_longitude].present?
      return render json: { 
        error: 'Destination location (to_latitude and to_longitude) is required' 
      }, status: :unprocessable_entity
    end

    unless params[:trip_type].present?
      return render json: { 
        error: 'Trip type is required (to_customer or to_home)' 
      }, status: :unprocessable_entity
    end

    unless %w[to_customer to_home].include?(params[:trip_type])
      return render json: { 
        error: 'Invalid trip type. Must be either to_customer or to_home' 
      }, status: :unprocessable_entity
    end

    # Check if journey of this type already exists - return 200 OK silently
    existing_journey = @order.journeys.find_by(trip_type: params[:trip_type])
    if existing_journey.present?
      return render json: { 
        message: "Journey already tracked",
        journey: {
          id: existing_journey.id,
          order_id: existing_journey.order_id,
          order_number: @order.order_number,
          trip_type: existing_journey.trip_type,
          distance_km: existing_journey.distance_km,
          amount: existing_journey.amount,
          traveled_at: existing_journey.traveled_at,
          from_location: {
            latitude: existing_journey.from_latitude,
            longitude: existing_journey.from_longitude
          },
          to_location: {
            latitude: existing_journey.to_latitude,
            longitude: existing_journey.to_longitude
          }
        },
        order_journeys: {
          total_count: @order.journeys.count,
          to_customer: @order.journeys.to_customer.exists?,
          to_home: @order.journeys.to_home.exists?
        }
      }, status: :ok
    end

    # Check if order already has 2 journeys - return 200 OK silently
    if @order.journeys.count >= 2
      return render json: { 
        message: "Maximum journeys already tracked for this order",
        order_journeys: {
          total_count: @order.journeys.count,
          to_customer: @order.journeys.to_customer.exists?,
          to_home: @order.journeys.to_home.exists?
        }
      }, status: :ok
    end

    begin
      # Calculate distance using Google Maps with motorcycle (driving) mode
      distance_km = nil
      
      # Calculate using route service with motorcycle optimized route
      begin
        maps_service = GoogleMapsService.new
        route_info = maps_service.calculate_route(
          params[:from_latitude].to_f,
          params[:from_longitude].to_f,
          params[:to_latitude].to_f,
          params[:to_longitude].to_f,
          travel_mode: 'driving' # Google Maps uses 'driving' for motorcycles
        )
        
        distance_km = route_info[:success] ? route_info[:distance][:kilometers] : calculate_straight_line_distance(
          params[:from_latitude].to_f,
          params[:from_longitude].to_f,
          params[:to_latitude].to_f,
          params[:to_longitude].to_f
        )
      rescue => e
        # Fallback to straight-line distance if route calculation fails
        Rails.logger.warn "Route calculation failed, using straight-line distance: #{e.message}"
        distance_km = calculate_straight_line_distance(
          params[:from_latitude].to_f,
          params[:from_longitude].to_f,
          params[:to_latitude].to_f,
          params[:to_longitude].to_f
        )
      end
      
      # Calculate amount based on distance and ta_amount config
      ta_amount = Rails.configuration.ta_amount
      calculated_amount = (distance_km * ta_amount).round(2)

      # Create journey record
      @journey = @order.journeys.build(
        user_id: current_user.id,
        from_latitude: params[:from_latitude],
        from_longitude: params[:from_longitude],
        to_latitude: params[:to_latitude],
        to_longitude: params[:to_longitude],
        distance_km: distance_km,
        amount: calculated_amount,
        trip_type: params[:trip_type],
        traveled_at: params[:traveled_at].presence || Time.current
      )

      if @journey.save
        render json: {
          message: "Journey tracked successfully",
          journey: {
            id: @journey.id,
            order_id: @journey.order_id,
            order_number: @order.order_number,
            trip_type: @journey.trip_type,
            distance_km: @journey.distance_km,
            amount: @journey.amount,
            traveled_at: @journey.traveled_at,
            from_location: {
              latitude: @journey.from_latitude,
              longitude: @journey.from_longitude
            },
            to_location: {
              latitude: @journey.to_latitude,
              longitude: @journey.to_longitude
            }
          },
          order_journeys: {
            total_count: @order.journeys.count,
            to_customer: @order.journeys.to_customer.exists?,
            to_home: @order.journeys.to_home.exists?
          }
        }, status: :created
      else
        render json: { errors: @journey.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Journey tracking error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { 
        error: "Failed to track journey: #{e.message}" 
      }, status: :internal_server_error
    end
  end

  private

  def calculate_straight_line_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    earth_radius_km = 6371

    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    (earth_radius_km * c).round(2)
  end

  def set_order
    @order = Order.find(params[:id])
    authorize! :read, @order
  end

  def apply_filters(orders)
    orders = orders.by_status(params[:status]) if params[:status].present?
    orders = orders.assigned_to(params[:assigned_to_id]) if params[:assigned_to_id].present?
    orders = orders.by_customer(params[:customer_id]) if params[:customer_id].present?
    orders = orders.by_date_range(params[:from_date], params[:to_date]) if params[:from_date] && params[:to_date]
    orders = orders.where(bookable_type: params[:bookable_type]) if params[:bookable_type].present?
    
    # General search across multiple fields with OR logic
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      orders = orders.joins(:customer).where(
        'LOWER(orders.order_number) LIKE LOWER(?) OR LOWER(customers.phone) LIKE LOWER(?) OR LOWER(customers.name) LIKE LOWER(?)',
        search_term, search_term, search_term
      )
    end
    
    # Specific field searches
    # orders = orders.where('LOWER(order_number) LIKE LOWER(?)', "%#{params[:order_number]}%") if params[:order_number].present?
    # orders = orders.joins(:customer).where('LOWER(customers.phone) LIKE LOWER(?)', "%#{params[:customer_phone]}%") if params[:customer_phone].present?
    orders
  end

  def should_recalculate?
    params[:recalculate_totals] == 'true'
  end

  def base_order_permitted_params
    [
      :customer_id,
      :booking_date,
      :booking_time_from,
      :booking_time_to,
      :notes,
      :contact_phone,
      :payment_method,
      :payment_status,
      :address_line1,
      :address_line2,
      :area,
      :city,
      :district,
      :state,
      :map_link,
      :latitude,
      :longitude,
      :received_amount,
      :tip,
      :customer_signature,
      :payment_proof,
      before_images: [],
      after_images: []
    ]
  end

  def order_create_params
    # Build a clean hash with all the data
    order_data = {}
    
    # Get base params from order key or root
    base_params = params[:order] || params
    
    # Extract all base order fields
    base_order_permitted_params.each do |field|
      value = base_params[field] || params[field]
      order_data[field] = value if value.present?
    end
    
    # Transform agent_id to assigned_to_id
    order_data[:assigned_to_id] = params[:agent_id] || base_params[:agent_id] || base_params[:assigned_to_id]
    
    # Handle booking_time (single field) or booking_time_from/to
    # Combine time with booking_date to create proper datetime
    booking_date = order_data[:booking_date]
    
    if params[:booking_time].present?
      time_value = parse_time_with_date(params[:booking_time], booking_date)
      order_data[:booking_time_from] = time_value
      order_data[:booking_time_to] = time_value
    else
      time_from = order_data[:booking_time_from]
      time_to = order_data[:booking_time_to]
      
      order_data[:booking_time_from] = parse_time_with_date(time_from, booking_date) if time_from.present?
      order_data[:booking_time_to] = parse_time_with_date(time_to, booking_date) if time_to.present?
    end
    
    
    # Handle packages array
    if params[:packages].present?
      order_data[:packages] = params[:packages].map do |pkg|
        pkg_hash = {
          package_id: pkg[:package_id],
          quantity: pkg[:quantity],
          price: pkg[:unit_price] || pkg[:price],
          vehicle_type: pkg[:vehicle_type].to_s.downcase,
          notes: pkg[:notes]
        }
        
        # Handle discount - include if not nil (allows 0)
        pkg_hash[:discount] = pkg[:discount_value] || pkg[:discount] unless (pkg[:discount_value] || pkg[:discount]).nil?
        
        pkg_hash.compact
      end
    end
    
    # Handle addons array
    if params[:addons].present?
      order_data[:addons] = params[:addons].map do |addon|
        addon_hash = {
          addon_id: addon[:addon_id],
          quantity: addon[:quantity],
          price: addon[:unit_price] || addon[:price]
        }
        
        # Handle discount - include if not nil (allows 0)
        addon_hash[:discount] = addon[:discount_value] || addon[:discount] unless (addon[:discount_value] || addon[:discount]).nil?
        
        addon_hash.compact
      end
    end
    
    order_data.compact
  end

  def order_update_params
    permitted_params = base_order_permitted_params.dup
    
    # Agents can update actual times
    if current_user.agent?
      permitted_params += [:actual_start_time, :actual_end_time]
    end
    
    # Restrict access for non-admin/non-sales_executive users
    unless current_user.admin? || current_user.sales_executive?
      # Only allow notes and agent-specific fields
      permitted_params = [:notes]
      permitted_params += [:actual_start_time, :actual_end_time] if current_user.agent?
    end
    
    # Permit nested address hash
    params.permit(permitted_params)
  end

  def status_params
    params.permit(:cancel_reason, :actual_start_time, :actual_end_time)
  end

  def feedback_params
    params.permit(:rating, :comments)
  end

  def parse_time_with_date(time_str, date_str)
    return nil if time_str.blank? || date_str.blank?
    
    # Parse the date
    date = date_str.is_a?(Date) ? date_str : Date.parse(date_str.to_s)
    
    # If time_str is already a datetime, return it
    return time_str if time_str.is_a?(DateTime) || time_str.is_a?(Time)
    
    # Parse time string (format: "12:30" or "12:30:00")
    time_parts = time_str.to_s.split(':')
    hour = time_parts[0].to_i
    minute = time_parts[1].to_i
    
    # Combine date and time
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end
end
