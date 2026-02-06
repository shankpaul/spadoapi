module Subscriptions
  class OrderGeneratorService
    attr_reader :errors, :generated_orders

    def initialize(days_ahead = 7)
      @days_ahead = days_ahead
      @errors = []
      @generated_orders = []
    end

    def generate_upcoming_orders
      subscription_orders = SubscriptionOrder.upcoming(@days_ahead)
                                            .includes(subscription: [:customer, :subscription_packages, :subscription_addons])

      subscription_orders.each do |subscription_order|
        generate_order_for_subscription(subscription_order)
      end

      {
        success: @errors.empty?,
        generated_count: @generated_orders.size,
        errors: @errors
      }
    end

    def generate_order_for_subscription(subscription_order)
      subscription = subscription_order.subscription
      
      # Skip if subscription is not active or scheduled
      unless subscription.scheduled? || subscription.active?
        return
      end

      ActiveRecord::Base.transaction do
        order = create_order(subscription, subscription_order)
        
        if order.persisted?
          subscription_order.update!(
            order_id: order.id,
            generated_at: Time.current
          )
          subscription_order.mark_generated!
          
          # Activate subscription on first order generation
          subscription.activate! if subscription.may_activate?
          
          @generated_orders << order
        else
          @errors << {
            subscription_id: subscription.id,
            scheduled_date: subscription_order.scheduled_date,
            errors: order.errors.full_messages
          }
          raise ActiveRecord::Rollback
        end
      end
    rescue StandardError => e
      @errors << {
        subscription_id: subscription.id,
        scheduled_date: subscription_order.scheduled_date,
        errors: [e.message]
      }
    end

    def success?
      @errors.empty?
    end

    private

    def create_order(subscription, subscription_order)
      customer = subscription.customer
      scheduled_date = subscription_order.scheduled_date

      # Parse time from subscription_order (format: "HH:MM:SS" or Time object)
      time_from = parse_time_with_date(subscription_order.time_from, scheduled_date)
      time_to = parse_time_with_date(subscription_order.time_to, scheduled_date)

      # Calculate which wash number this is for the subscription
      wash_number = calculate_wash_number(subscription, subscription_order)

      # Prepare packages data from subscription_packages
      packages_data = subscription.subscription_packages.map do |sub_pkg|
        {
          package_id: sub_pkg.package_id,
          quantity: sub_pkg.quantity,
          unit_price: sub_pkg.unit_price,
          price: 0, # Zero price since subscription is already paid
          vehicle_type: sub_pkg.vehicle_type,
          discount: 0, # No discount on packages in subscription
          discount_type: sub_pkg.discount_type,
          notes: sub_pkg.notes,
          discount_value: 0
        }
      end

      # Prepare addons data from subscription_addons - only include addons applicable to this wash number
      addons_data = subscription.subscription_addons.select do |sub_addon|
        # Include addon if it applies to this wash number
        sub_addon.applies_to_wash?(wash_number)
      end.map do |sub_addon|
        {
          addon_id: sub_addon.addon_id,
          quantity: sub_addon.quantity,
          unit_price: sub_addon.unit_price,
          price: 0, # Zero price since subscription is already paid
          discount: 0, # No discount on addons in subscription
          discount_type: sub_addon.discount_type,
          discount_value: 0
        }
      end

      # Prepare order data
      order_data = {
        customer_id: customer.id,
        subscription_id: subscription.id,
        booking_date: scheduled_date,
        booking_time_from: time_from,
        booking_time_to: time_to,
        contact_phone: customer.phone,
        address_line1: customer.address_line1,
        address_line2: customer.address_line2,
        area: subscription.area || customer.area,
        city: customer.city,
        district: customer.district,
        state: customer.state,
        latitude: customer.latitude,
        longitude: customer.longitude,
        map_link: subscription.map_url || customer.map_link,
        notes: "Auto-generated from subscription ##{subscription.id} (Wash ##{wash_number})",
        status: :tentative,
        assigned_to_id: nil, # No agent assignment initially
        packages: packages_data,
        addons: addons_data.any? ? addons_data : nil
      }

      # Use the existing Orders::CreationService
      service = Orders::CreationService.new(order_data, subscription.created_by, bookable_entity: subscription)
      order = service.create

      if service.success?
        order
      else
        # Create a new order object with errors for error handling
        Order.new.tap do |o|
          service.errors.each { |error| o.errors.add(:base, error) }
        end
      end
    end

    # Calculate which wash number this order represents in the subscription sequence
    def calculate_wash_number(subscription, current_subscription_order)
      # Get all subscription orders for this subscription ordered by scheduled date
      ordered_subscription_orders = subscription.subscription_orders.order(scheduled_date: :asc)
      
      # Find the index of the current subscription order (1-based)
      wash_number = ordered_subscription_orders.index(current_subscription_order).to_i + 1
      
      wash_number
    end

    def parse_time_with_date(time_value, date)
      return nil if time_value.blank? || date.blank?

      date = Date.parse(date.to_s) unless date.is_a?(Date)
      
      # If time_value is already a Time/DateTime object, extract hour and minute
      if time_value.is_a?(Time) || time_value.is_a?(DateTime)
        Time.zone.local(date.year, date.month, date.day, time_value.hour, time_value.min)
      else
        # Parse time string (format: "HH:MM:SS" or "HH:MM")
        time_parts = time_value.to_s.split(':')
        hour = time_parts[0].to_i
        minute = time_parts[1].to_i
        
        Time.zone.local(date.year, date.month, date.day, hour, minute)
      end
    end
  end
end
