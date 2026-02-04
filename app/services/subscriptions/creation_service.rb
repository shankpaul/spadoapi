module Subscriptions
  class CreationService
    attr_reader :subscription, :errors

    def initialize(params, current_user)
      @params = params
      @current_user = current_user
      @errors = []
      @subscription = nil
    end

    def create
      validate_params
      return nil if @errors.any?

      ActiveRecord::Base.transaction do
        create_subscription
        create_subscription_packages
        create_subscription_addons
        create_subscription_order_placeholders
      end

      @subscription
    rescue StandardError => e
      @errors << e.message
      nil
    end

    def success?
      @errors.empty? && @subscription.present?
    end

    private

    def validate_params
      @errors << "Customer is required" unless @params[:customer_id].present?
      @errors << "Vehicle type is required" unless @params[:vehicle_type].present?
      @errors << "Start date is required" unless @params[:start_date].present?
      @errors << "Months duration is required" unless @params[:months_duration].present?
      @errors << "Washing schedules are required" unless @params[:washing_schedules].present? && @params[:washing_schedules].any?
      @errors << "At least one package is required" unless @params[:packages].present? && @params[:packages].any?

      return if @errors.any?

      # Validate packages exist and are subscription enabled
      @params[:packages].each do |pkg_data|
        package = Package.find_by(id: pkg_data[:package_id])
        unless package
          @errors << "Package with ID #{pkg_data[:package_id]} not found"
          next
        end

        unless package.subscription_enabled?
          @errors << "Package '#{package.name}' is not available for subscription"
        end
      end
    end

    def create_subscription
      @subscription = Subscription.new(
        customer_id: @params[:customer_id],
        vehicle_type: @params[:vehicle_type],
        start_date: @params[:start_date],
        months_duration: @params[:months_duration],
        washing_schedules: @params[:washing_schedules],
        number_of_orders: @params[:washing_schedules].size,
        completed_no_orders: 0,
        subscription_amount: calculate_subscription_amount,
        payment_amount: @params[:payment_amount] || 0.0,
        payment_date: @params[:payment_date],
        payment_method: @params[:payment_method],
        map_url: @params[:map_url],
        area: @params[:area],
        notes: @params[:notes],
        created_by: @current_user,
        status: :scheduled
      )

      unless @subscription.save
        @errors.concat(@subscription.errors.full_messages)
        raise ActiveRecord::Rollback
      end
      
      # Mark as paid if payment covers full amount
      if @subscription.payment_amount >= @subscription.subscription_amount
        @subscription.mark_paid!
      end
    end

    def calculate_subscription_amount
      # Calculate based on subscription packages and addons
      total = 0
      
      @params[:packages].each do |pkg|
        quantity = pkg[:quantity] || 1
        price = pkg[:price] || pkg[:unit_price]
        discount_value = pkg[:discount_value] || 0
        
        total += (price * quantity - discount_value)
      end
      
      if @params[:addons].present?
        @params[:addons].each do |addon|
          quantity = addon[:quantity] || 1
          price = addon[:price] || addon[:unit_price]
          discount_value = addon[:discount_value] || 0
          
          total += (price * quantity - discount_value)
        end
      end
      
      total * @params[:months_duration].to_i
    end

    def create_subscription_packages
      @params[:packages].each do |pkg_data|
        package = Package.find(pkg_data[:package_id])
        
        quantity = pkg_data[:quantity] || 1
        unit_price = pkg_data[:unit_price] || package.unit_price
        price = pkg_data[:price] || unit_price
        discount = pkg_data[:discount]
        discount_type = pkg_data[:discount_type]
        discount_value = pkg_data[:discount_value] || 0
        
        subscription_package = @subscription.subscription_packages.build(
          package_id: pkg_data[:package_id],
          quantity: quantity,
          unit_price: unit_price,
          price: price,
          vehicle_type: pkg_data[:vehicle_type] || @params[:vehicle_type],
          discount: discount,
          discount_type: discount_type,
          discount_value: discount_value,
          notes: pkg_data[:notes]
        )
        
        unless subscription_package.save
          @errors.concat(subscription_package.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end
    end

    def create_subscription_addons
      return unless @params[:addons].present?
      
      @params[:addons].each do |addon_data|
        addon = Addon.find(addon_data[:addon_id])
        
        quantity = addon_data[:quantity] || 1
        unit_price = addon_data[:unit_price] || addon.price
        price = addon_data[:price] || unit_price
        discount = addon_data[:discount]
        discount_type = addon_data[:discount_type]
        discount_value = addon_data[:discount_value] || 0
        
        subscription_addon = @subscription.subscription_addons.build(
          addon_id: addon_data[:addon_id],
          quantity: quantity,
          unit_price: unit_price,
          price: price,
          discount: discount,
          discount_type: discount_type,
          discount_value: discount_value
        )
        
        unless subscription_addon.save
          @errors.concat(subscription_addon.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end
    end

    def create_subscription_order_placeholders
      # Create subscription_order records for each washing schedule
      # These will be used to track which orders have been generated
      @params[:washing_schedules].each do |schedule|
        subscription_order = @subscription.subscription_orders.build(
          scheduled_date: schedule['date'],
          time_from: schedule['time_from'],
          time_to: schedule['time_to'],
          status: :pending_generation
        )

        unless subscription_order.save
          @errors.concat(subscription_order.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
