class EndOfDayLog < ApplicationRecord
  belongs_to :agent, class_name: 'User'

  validates :date, presence: true
  validates :check_out_time, presence: true
  validates :latitude, :longitude, presence: true
  validates :agent_id, uniqueness: { scope: :date, message: "End of day report already submitted for today" }

  before_validation :set_date

  private

  def set_date
    self.date ||= check_out_time.to_date if check_out_time
  end
end
