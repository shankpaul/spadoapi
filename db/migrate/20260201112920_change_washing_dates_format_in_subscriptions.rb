class ChangeWashingDatesFormatInSubscriptions < ActiveRecord::Migration[8.0]
  def change
    # Remove the old date array column
    remove_column :subscriptions, :washing_dates, :date, array: true, default: []
    
    # Add new JSONB column for washing schedules with date and time slots
    add_column :subscriptions, :washing_schedules, :jsonb, default: []
  end
end
