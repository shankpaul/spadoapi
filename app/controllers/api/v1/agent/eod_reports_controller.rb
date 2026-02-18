class Api::V1::Agent::EodReportsController < ApplicationController
  before_action :authenticate_request!
  
  # POST /api/v1/agent/eod_report
  def create
    @report = current_user.end_of_day_logs.new(eod_params)
    @report.check_out_time = Time.zone.parse(params[:check_out_time]) if params[:check_out_time].present?
    
    if @report.save
      render json: {
        message: "Day completed successfully! Thank you for your hard work today.",
        check_out_time: @report.check_out_time
      }, status: :created
    else
      render json: { errors: @report.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/agent/eod_report/today
  def today
    @report = current_user.end_of_day_logs.find_by(date: Date.current)
    if @report
      render json: {
        submitted: true,
        check_out_time: @report.check_out_time,
        cash_in_hand: @report.cash_in_hand,
        distance_travelled: @report.distance_travelled
      }
    else
      render json: { submitted: false }
    end
  end

  private

  def eod_params
    params.permit(:latitude, :longitude, :cash_in_hand, :distance_travelled, :notes)
  end
end
