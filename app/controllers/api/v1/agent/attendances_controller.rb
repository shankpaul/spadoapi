class Api::V1::Agent::AttendancesController < ApplicationController
  before_action :authenticate_request!
  
  # POST /api/v1/agent/attendance
  def create
    @attendance = current_user.attendances.new(attendance_params)
    @attendance.check_in_time = Time.zone.parse(params[:check_in_time]) if params[:check_in_time].present?
    
    if @attendance.save
      render json: {
        message: "Attendance marked successfully",
        is_late: @attendance.is_late,
        check_in_time: @attendance.check_in_time
      }, status: :created
    else
      render json: { errors: @attendance.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/agent/attendance/today
  def today
    @attendance = current_user.attendances.find_by(date: Date.current)
    if @attendance
      render json: {
        marked: true,
        is_late: @attendance.is_late,
        check_in_time: @attendance.check_in_time
      }
    else
      render json: { marked: false }
    end
  end

  private

  def attendance_params
    params.permit(:latitude, :longitude)
  end
end
