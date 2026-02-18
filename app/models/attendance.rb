class Attendance < ApplicationRecord
  belongs_to :agent, class_name: 'User'

  validates :date, presence: true
  validates :check_in_time, presence: true
  validates :latitude, :longitude, presence: true
  validates :agent_id, uniqueness: { scope: :date, message: "Attendance already marked for today" }

  before_validation :set_date
  before_save :check_if_late

  private

  def set_date
    self.date ||= check_in_time.to_date if check_in_time
  end

  def check_if_late
    return if check_in_time.blank?
    
    # 9:00 AM threshold
    late_threshold = check_in_time.beginning_of_day + 9.hours
    self.is_late = check_in_time > late_threshold
  end
end
