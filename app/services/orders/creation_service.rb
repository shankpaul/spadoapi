module Orders
  class CreationService
    attr_reader :params, :current_user, :order, :errors

    def initialize(params, current_user)
      @params = params
      @current_user = current_user
      @errors = []
    end

    def self.call(params, current_user)
      new(params, current_user).create
    end

    def create
      max_retries = 3
      retry_count = 0

      # begin
      #   ActiveRecord::Base.transaction do
          create_order
          copy_address_from_customer
          create_packages
          create_addons
          calculate_totals
          
          @order
      #   end
      # rescue ActiveRecord::RecordNotUnique => e
      #   retry_count += 1
      #   if retry_count < max_retries
      #     sleep(0.1 * retry_count) # Brief delay before retry
      #     retry
      #   else
      #     @errors << "Unable to generate unique order number after #{max_retries} attempts. Please try again."
      #     nil
      #   end
      # rescue ActiveRecord::RecordInvalid => e
      #   @errors << e.message
      #   nil
      # rescue => e
      #   @errors << e.message
      #   nil
      # end
    end

    def success?
      errors.empty? && order.present?
    end

    private

    def create_order
      @order = Order.new(order_params)
      @order.bookable = current_user
      
      # Set address fields from params or customer before validation
      customer = Customer.find(params[:customer_id])
      @order.contact_phone = params[:contact_phone] || customer.phone
      @order.address_line1 = params[:address_line1] || customer.address_line1
      @order.address_line2 = params[:address_line2] || customer.address_line2
      @order.area = params[:area] || customer.area
      @order.city = params[:city] || customer.city
      @order.state = params[:state] || customer.state
      @order.latitude = params[:latitude] || customer.latitude
      @order.longitude = params[:longitude] || customer.longitude
      @order.map_link = params[:map_link] || customer.map_link
      
      @order.save!
    end

    def copy_address_from_customer
      # Address already copied in create_order
    end

    def create_packages
      return unless params[:packages].present?

      params[:packages].each do |package_params|
        package = Package.find(package_params[:package_id])
        
        # Use unit_price from params or package default
        price = (package_params[:unit_price] || package_params[:price] || package.unit_price).to_f
        
        # Calculate discount based on discount_type
        discount = calculate_discount(price, package_params)
        
        order_package = @order.order_packages.build(
          package: package,
          quantity: package_params[:quantity] || 1,
          price: price,
          vehicle_type: package_params[:vehicle_type] || package.vehicle_type,
          discount: discount,
          notes: package_params[:notes]
        )
        # total_price calculated by callback
        order_package.save!
      end
    end

    def create_addons
      return unless params[:addons].present?

      params[:addons].each do |addon_params|
        addon = Addon.find(addon_params[:addon_id])
        
        # Use unit_price from params or addon default
        price = (addon_params[:unit_price] || addon_params[:price] || addon.price).to_f
        
        # Calculate discount based on discount_type
        discount = calculate_discount(price, addon_params)
        
        order_addon = @order.order_addons.build(
          addon: addon,
          quantity: addon_params[:quantity] || 1,
          price: price,
          discount: discount
        )
        # total_price calculated by callback
        order_addon.save!
      end
    end

    def calculate_discount(price, item_params)
      discount_value = item_params[:discount_value]
      return 0 if discount_value.nil? || discount_value.to_s.empty?
      
      discount_value = discount_value.to_f
      discount_type = item_params[:discount_type]
      
      if discount_type == 'percentage'
        (price * discount_value / 100).round(2)
      else
        discount_value
      end
    end

    def calculate_totals
      Orders::CalculationService.call(@order)
    end

    def order_params
      # Params is already a hash from controller with permitted values
      # Don't include status - AASM manages it with initial state
      params.slice(
        :customer_id,
        :booking_date,
        :booking_time_from,
        :booking_time_to,
        :assigned_to_id,
        :notes,
        :payment_method
      )
    end
  end
end
