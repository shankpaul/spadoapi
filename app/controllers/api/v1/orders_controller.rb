class Api::V1::OrdersController < ApplicationController
  before_action :authenticate_request!
  load_and_authorize_resource except: [:create]
  before_action :set_order, only: [:show, :update, :destroy, :assign, :reassign, :update_status, :cancel, :feedback, :reassignments, :timeline]
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
      
      @message = "Order created successfully"
      render :show, status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/orders/:id
  def update
    if @order.update(order_update_params)
      # Recalculate totals if packages or addons were updated
      Orders::CalculationService.call(@order) if should_recalculate?
      
      @message = "Order updated successfully"
      render :show
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
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

  private

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

  def order_create_params
    # Build a clean hash with all the data
    order_data = {}
    
    # Get base params from order key or root
    base_params = params[:order] || params
    
    # Copy allowed fields
    order_data[:customer_id] = base_params[:customer_id] || params[:customer_id]
    order_data[:booking_date] = base_params[:booking_date] || params[:booking_date]
    order_data[:notes] = base_params[:notes] || params[:notes]
    order_data[:contact_phone] = base_params[:contact_phone] || params[:contact_phone]
    order_data[:address_line1] = base_params[:address_line1] || params[:address_line1]
    order_data[:address_line2] = base_params[:address_line2] || params[:address_line2]
    
    # Handle payment_method enum - only include if present
    payment_method = base_params[:payment_method] || params[:payment_method]
    order_data[:payment_method] = payment_method if payment_method.present?
    
    # Transform agent_id to assigned_to_id
    order_data[:assigned_to_id] = params[:agent_id] || base_params[:agent_id] || base_params[:assigned_to_id]
    
    # Handle booking_time (single field) or booking_time_from/to
    # Combine time with booking_date to create proper datetime
    booking_date = base_params[:booking_date] || params[:booking_date]
    
    if params[:booking_time].present?
      time_value = parse_time_with_date(params[:booking_time], booking_date)
      order_data[:booking_time_from] = time_value
      order_data[:booking_time_to] = time_value
    else
      time_from = base_params[:booking_time_from] || params[:booking_time_from]
      time_to = base_params[:booking_time_to] || params[:booking_time_to]
      
      order_data[:booking_time_from] = parse_time_with_date(time_from, booking_date) if time_from.present?
      order_data[:booking_time_to] = parse_time_with_date(time_to, booking_date) if time_to.present?
    end
    
    # Handle nested address hash
    if params[:address].present?
      address = params[:address]
      order_data[:area] = address[:area] if address[:area].present?
      order_data[:city] = address[:city] if address[:city].present?
      order_data[:district] = address[:district] if address[:district].present?
      order_data[:state] = address[:state] if address[:state].present?
      order_data[:map_link] = address[:map_link] if address[:map_link].present?
      order_data[:latitude] = address[:latitude] if address[:latitude].present?
      order_data[:longitude] = address[:longitude] if address[:longitude].present?
    else
      order_data[:area] = base_params[:area] || params[:area]
      order_data[:city] = base_params[:city] || params[:city]
      order_data[:district] = base_params[:district] || params[:district]
      order_data[:state] = base_params[:state] || params[:state]
      order_data[:map_link] = base_params[:map_link] || params[:map_link]
      order_data[:latitude] = base_params[:latitude] || params[:latitude]
      order_data[:longitude] = base_params[:longitude] || params[:longitude]
    end
    
    # Handle packages array
    if params[:packages].present?
      order_data[:packages] = params[:packages].map do |pkg|
        pkg_hash = {
          package_id: pkg[:package_id],
          quantity: pkg[:quantity],
          unit_price: pkg[:unit_price],
          vehicle_type: pkg[:vehicle_type].to_s.downcase,
          discount_type: pkg[:discount_type],
          notes: pkg[:notes]
        }
        
        # Include price if present
        pkg_hash[:price] = pkg[:price] if pkg[:price].present?
        
        # Handle discount - include if not nil (allows 0)
        pkg_hash[:discount] = pkg[:discount] unless pkg[:discount].nil?
        
        # Handle discount_value - include if not nil (allows 0)
        pkg_hash[:discount_value] = pkg[:discount_value] unless pkg[:discount_value].nil?
        
        pkg_hash.compact
      end
    end
    
    # Handle addons array
    if params[:addons].present?
      order_data[:addons] = params[:addons].map do |addon|
        addon_hash = {
          addon_id: addon[:addon_id],
          quantity: addon[:quantity],
          unit_price: addon[:unit_price],
          discount_type: addon[:discount_type]
        }
        
        # Include price if present
        addon_hash[:price] = addon[:price] if addon[:price].present?
        
        # Handle discount - include if not nil (allows 0)
        addon_hash[:discount] = addon[:discount] unless addon[:discount].nil?
        
        # Handle discount_value - include if not nil (allows 0)
        addon_hash[:discount_value] = addon[:discount_value] unless addon[:discount_value].nil?
        
        addon_hash.compact
      end
    end
    
    order_data.compact
  end

  def order_update_params
    permitted_params = [:notes]
    
    # Sales executives and admins can update more fields
    if current_user.admin? || current_user.sales_executive?
      permitted_params += [
        :booking_date,
        :booking_time_from,
        :booking_time_to,
        :payment_method,
        :payment_status
      ]
    end
    
    # Agents can update actual times
    if current_user.agent?
      permitted_params += [:actual_start_time, :actual_end_time]
    end
    
    params.require(:order).permit(permitted_params)
  end

  def status_params
    params.permit(:cancel_reason, :actual_start_time, :actual_end_time)
  end

  def feedback_params
    params.require(:order).permit(:rating, :comments)
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
