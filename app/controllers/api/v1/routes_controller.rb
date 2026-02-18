class Api::V1::RoutesController < ApplicationController
  before_action :authenticate_request!

  # POST /api/v1/routes/calculate
  # Calculate route between two locations
  def calculate
    # Validate required parameters
    unless params[:from_latitude].present? && params[:from_longitude].present?
      return render json: { 
        error: 'Starting location (from_latitude and from_longitude) is required' 
      }, status: :unprocessable_entity
    end

    unless params[:to_latitude].present? && params[:to_longitude].present?
      return render json: { 
        error: 'Destination location (to_latitude and to_longitude) is required' 
      }, status: :unprocessable_entity
    end

    begin
      # Calculate route using Google Maps Directions API
      travel_mode = params[:travel_mode].presence || 'driving'
      maps_service = GoogleMapsService.new
      route_info = maps_service.calculate_route(
        params[:from_latitude].to_f,
        params[:from_longitude].to_f,
        params[:to_latitude].to_f,
        params[:to_longitude].to_f,
        travel_mode: travel_mode
      )

      if route_info[:success]
        render json: {
          success: true,
          route: {
            distance_km: route_info[:distance][:kilometers],
            distance_text: route_info[:distance][:text],
            duration_minutes: route_info[:duration][:minutes],
            duration_text: route_info[:duration][:text],
            start_address: route_info[:start_address],
            end_address: route_info[:end_address],
            start_location: route_info[:start_location],
            end_location: route_info[:end_location],
            
            # Polyline for drawing route on map
            overview_polyline: route_info[:overview_polyline],
            
            # Step-by-step navigation
            steps: route_info[:steps],
            
            # Map viewport bounds
            bounds: route_info[:bounds],
            
            # Attribution
            copyrights: route_info[:copyrights]
          },
          summary: {
            distance: "#{route_info[:distance][:kilometers]} km",
            estimated_time: "#{route_info[:duration][:minutes]} minutes",
            message: "Best route calculated successfully"
          }
        }, status: :ok
      else
        render json: { 
          success: false,
          error: route_info[:error] 
        }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Route calculation error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { 
        success: false,
        error: "Failed to calculate route: #{e.message}" 
      }, status: :internal_server_error
    end
  end
end
