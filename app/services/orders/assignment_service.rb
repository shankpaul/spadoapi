module Orders
  class AssignmentService
    attr_reader :order, :agent_id, :current_user, :errors, :notes

    def initialize(order, agent_id, current_user, notes = nil)
      @order = order
      @agent_id = agent_id
      @current_user = current_user
      @notes = notes
      @errors = []
    end

    def self.call(order, agent_id, current_user, notes = nil)
      new(order, agent_id, current_user, notes).assign
    end

    def assign
      return false unless validate_assignment

      begin
        ActiveRecord::Base.transaction do
          set_current_user
          update_assignment
          create_history_entry
          
          order
        end
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

    def validate_assignment
      agent = User.find_by(id: agent_id)
      
      unless agent
        @errors << "Agent not found"
        return false
      end

      unless agent.agent?
        @errors << "User must have agent role to be assigned orders"
        return false
      end

      if agent.deleted?
        @errors << "Cannot assign to deleted/inactive agent"
        return false
      end

      # Check booking conflicts if order has booking time
      if order.booking_date && order.booking_time_from && order.booking_time_to
        if has_booking_conflict?(agent)
          @errors << "Agent is not available during the booking time"
          return false
        end
      end

      true
    end

    def has_booking_conflict?(agent)
      buffer_minutes = Setting.booking_buffer_minutes
      
      conflicting_orders = Order.where(assigned_to_id: agent.id, booking_date: order.booking_date)
                                .where.not(id: order.id)
                                .where.not(status: [:cancelled, :completed])
                                .where("booking_time_from < ? AND booking_time_to > ?", 
                                       order.booking_time_to + buffer_minutes.minutes,
                                       order.booking_time_from - buffer_minutes.minutes)
      
      conflicting_orders.exists?
    end

    def set_current_user
      Current.user = current_user
    end

    def update_assignment
      order.assigned_to_id = agent_id
      order.save!
    end

    def create_history_entry
      order.assignment_histories.create!(
        assigned_to_id: agent_id,
        assigned_by: current_user,
        assigned_at: Time.current,
        status: order.status,
        notes: notes
      )
    end
  end
end
