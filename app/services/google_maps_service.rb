class GoogleMapsService
  include HTTParty
  base_uri 'https://maps.googleapis.com/maps/api'

  def initialize
    @api_key = Rails.application.credentials.dig(:google_maps, :api_key) || ENV['GOOGLE_MAPS_API_KEY']
    raise "Google Maps API key not configured" if @api_key.blank?
  end

  # Calculate route distance and directions between two points
  # @param origin_lat [Float] Starting latitude
  # @param origin_lng [Float] Starting longitude
  # @param dest_lat [Float] Destination latitude
  # @param dest_lng [Float] Destination longitude
  # @param travel_mode [String] Travel mode: 'driving', 'walking', 'bicycling', 'transit'
  # @return [Hash] Route information including distance, duration, and polyline
  def calculate_route(origin_lat, origin_lng, dest_lat, dest_lng, travel_mode: 'driving')
    origin = "#{origin_lat},#{origin_lng}"
    destination = "#{dest_lat},#{dest_lng}"

    response = self.class.get('/directions/json', {
      query: {
        origin: origin,
        destination: destination,
        key: @api_key,
        mode: travel_mode,
        alternatives: false, # Set to true if you want alternative routes
        language: 'en',
        units: 'metric'
      }
    })

    if response.success? && response['status'] == 'OK'
      parse_directions_response(response)
    else
      error_message = response['error_message'] || response['status'] || 'Unknown error'
      raise "Google Maps API error: #{error_message}"
    end
  rescue => e
    Rails.logger.error "Google Maps Service Error: #{e.message}"
    {
      success: false,
      error: e.message
    }
  end

  private

  def parse_directions_response(response)
    route = response['routes'].first
    leg = route['legs'].first

    {
      success: true,
      distance: {
        value: leg['distance']['value'], # meters
        text: leg['distance']['text'],   # e.g., "5.2 km"
        kilometers: (leg['distance']['value'] / 1000.0).round(2)
      },
      duration: {
        value: leg['duration']['value'], # seconds
        text: leg['duration']['text'],   # e.g., "15 mins"
        minutes: (leg['duration']['value'] / 60.0).round(0)
      },
      start_address: leg['start_address'],
      end_address: leg['end_address'],
      start_location: leg['start_location'],
      end_location: leg['end_location'],
      
      # Encoded polyline for the entire route
      overview_polyline: route['overview_polyline']['points'],
      
      # Detailed step-by-step instructions
      steps: leg['steps'].map do |step|
        {
          distance: {
            value: step['distance']['value'],
            text: step['distance']['text']
          },
          duration: {
            value: step['duration']['value'],
            text: step['duration']['text']
          },
          start_location: step['start_location'],
          end_location: step['end_location'],
          html_instructions: step['html_instructions'],
          travel_mode: step['travel_mode'],
          polyline: step['polyline']['points'],
          maneuver: step['maneuver']
        }
      end,
      
      # Route bounds for map viewport
      bounds: route['bounds'],
      
      # Warnings and copyrights
      warnings: route['warnings'],
      copyrights: route['copyrights']
    }
  end
end
