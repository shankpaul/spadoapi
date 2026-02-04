class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_request!
  load_and_authorize_resource except: [:create]
  before_action :set_subscription, only: [:show, :update, :pause, :resume, :cancel, :update_payment]
  respond_to :json

  # GET /api/v1/subscriptions
  def index
    @subscriptions = apply_filters(@subscriptions)
    @subscriptions = @subscriptions.includes(:customer, :created_by, :subscription_packages, :packages)
                                   .order(created_at: :desc)
                                   .page(params[:page])
                                   .per(params[:per_page] || 25)
  end

  # GET /api/v1/subscriptions/:id
  def show
    @subscription = Subscription.includes(:customer, :created_by, :subscription_orders, :orders, 
                                          :subscription_packages, :packages, :subscription_addons, :addons)
                                .find(@subscription.id)
  end

  # POST /api/v1/subscriptions
  def create
    authorize! :create, Subscription
    
    service = Subscriptions::CreationService.new(subscription_create_params, current_user)
    @subscription = service.create

    if service.success?
      @message = "Subscription created successfully"
      render :show, status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/subscriptions/:id
  def update
    if @subscription.update(subscription_update_params)
      @message = "Subscription updated successfully"
      render :show
    else
      render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/subscriptions/:id/pause
  def pause
    unless @subscription.may_pause?
      return render json: { errors: ["Cannot pause subscription in current state"] }, status: :unprocessable_entity
    end

    if @subscription.pause!
      @message = "Subscription paused successfully"
      render :show
    else
      render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/subscriptions/:id/resume
  def resume
    unless @subscription.may_resume?
      return render json: { errors: ["Cannot resume subscription in current state"] }, status: :unprocessable_entity
    end

    if @subscription.resume!
      @message = "Subscription resumed successfully"
      render :show
    else
      render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/subscriptions/:id/cancel
  def cancel
    unless @subscription.may_cancel?
      return render json: { errors: ["Cannot cancel subscription in current state"] }, status: :unprocessable_entity
    end

    if @subscription.cancel!
      @message = "Subscription cancelled successfully"
      render :show
    else
      render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/subscriptions/:id/update_payment
  def update_payment
    payment_params = params.permit(:payment_amount, :payment_date, :payment_method)
    
    unless payment_params[:payment_amount].present?
      return render json: { errors: ["Payment amount is required"] }, status: :unprocessable_entity
    end

    # Calculate new payment amount
    total_paid = @subscription.payment_amount.to_f + payment_params[:payment_amount].to_f

    update_data = {
      payment_amount: total_paid
    }
    update_data[:payment_date] = payment_params[:payment_date] if payment_params[:payment_date].present?
    update_data[:payment_method] = payment_params[:payment_method] if payment_params[:payment_method].present?

    if @subscription.update(update_data)
      # Update payment status based on total paid
      if total_paid >= @subscription.subscription_amount && @subscription.may_mark_paid?
        @subscription.mark_paid!
      end
      
      @message = "Payment updated successfully"
      render :show
    else
      render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/subscriptions/:id/orders
  def orders
    @orders = @subscription.orders
                          .includes(:customer, :assigned_to, :packages, :addons)
                          .order(booking_date: :asc)
                          .page(params[:page])
                          .per(params[:per_page] || 25)
    
    render 'api/v1/orders/index'
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
    authorize! :read, @subscription
  end

  def apply_filters(subscriptions)
    subscriptions = subscriptions.by_customer(params[:customer_id]) if params[:customer_id].present?
    subscriptions = subscriptions.by_status(params[:status]) if params[:status].present?
    
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      subscriptions = subscriptions.joins(:customer).where(
        'LOWER(customers.name) LIKE LOWER(?) OR LOWER(customers.phone) LIKE LOWER(?)',
        search_term, search_term
      )
    end
    
    subscriptions
  end

  def subscription_create_params
    {
      customer_id: params[:customer_id],
      vehicle_type: params[:vehicle_type],
      start_date: params[:start_date],
      months_duration: params[:months_duration],
      washing_schedules: params[:washing_schedules],
      packages: params[:packages],
      addons: params[:addons],
      payment_amount: params[:payment_amount],
      payment_date: params[:payment_date],
      payment_method: params[:payment_method],
      map_url: params[:map_url],
      area: params[:area],
      notes: params[:notes]
    }.compact
  end

  def subscription_update_params
    params.permit(:notes, :payment_method, :map_url, :area)
  end
end
