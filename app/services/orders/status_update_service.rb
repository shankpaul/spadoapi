module Orders
  class StatusUpdateService
    attr_reader :order, :new_status, :current_user, :errors, :additional_params

    def initialize(order, new_status, current_user, additional_params = {})
      @order = order
      @new_status = new_status.to_sym
      @current_user = current_user
      @additional_params = additional_params
      @errors = []
    end

    def self.call(order, new_status, current_user, additional_params = {})
      new(order, new_status, current_user, additional_params).update_status
    end

    def update_status
      return false unless validate_transition

      begin
        ActiveRecord::Base.transaction do
          set_current_user
          update_additional_fields
          perform_transition
          
          order
        end
      rescue AASM::InvalidTransition => e
        @errors << "Invalid status transition: #{e.message}"
        nil
      rescue ActiveRecord::RecordInvalid => e
        @errors << e.message
        nil
      rescue => e
        @errors << e.message
        nil
      end
    end

    def success?
      errors.empty?
    end

    private

    def validate_transition
      unless can_transition?
        @errors << "You don't have permission to change order status to #{new_status}"
        return false
      end

      if new_status == :cancelled && additional_params[:cancel_reason].blank?
        @errors << "Cancel reason is required when cancelling an order"
        return false
      end

      true
    end

    def can_transition?
      # Define role-based permissions for status transitions
      case new_status
      when :mark_tentative, :confirm_booking, :tentative, :confirmed
        current_user.admin? || current_user.sales_executive?
      when :start_service, :complete_service, :in_progress, :completed
        current_user.admin? || current_user.sales_executive? || current_user.agent?
      when :cancel_order, :cancelled
        current_user.admin? || current_user.sales_executive?
      else
        false
      end
    end

    def set_current_user
      Current.user = current_user
    end

    def update_additional_fields
      case new_status
      when :cancelled, :cancel_order
        order.cancelled_by = current_user
        order.cancel_reason = additional_params[:cancel_reason]
      when :start_service, :in_progress
        order.actual_start_time = additional_params[:actual_start_time] || Time.current
      when :complete_service, :completed
        order.actual_end_time = additional_params[:actual_end_time] || Time.current
      end
    end

    def perform_transition
      # Map new_status to AASM events
      event = case new_status
              when :tentative then :mark_tentative
              when :confirmed then :confirm_booking
              when :in_progress then :start_service
              when :completed then :complete_service
              when :cancelled then :cancel_order
              else new_status
              end

      order.send("#{event}!")
    end
  end
end
