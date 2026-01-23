module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :track_user_activity
    
    rescue_from CanCan::AccessDenied do |exception|
      render json: { error: exception.message }, status: :forbidden
    end
  end

  private

  def authenticate_request!
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    
    secret_key = Rails.application.credentials.devise_jwt_secret_key || 
                 ENV['DEVISE_JWT_SECRET_KEY'] || 
                 '13b5739f715e7ae1e0a342968d2e1b17c450b9ec9fbe50e2659d4a508494fe00240e93840cbbf360be1b0f8898ff729a5053cf6245502cd07ff7b9b43726ff64'
    
    begin
      decoded = JWT.decode(
        token,
        secret_key,
        true,
        { 
          algorithm: 'HS256',
          verify_aud: true,
          aud: 'JWT_AUD'
        }
      )
      @current_user = User.find(decoded[0]['sub'])
    rescue JWT::InvalidAudError => e
      render_unauthorized("Invalid audience: #{e.message}")
    rescue JWT::DecodeError => e
      render_unauthorized("Decode error: #{e.message}")
    rescue JWT::ExpiredSignature
      render_unauthorized('Token has expired')
    rescue ActiveRecord::RecordNotFound
      render_unauthorized('User not found')
    rescue => e
      render_unauthorized("Authentication error: #{e.class} - #{e.message}")
    end
  end

  def current_user
    @current_user
  end

  def track_user_activity
    current_user&.update_last_activity!
  rescue
    # Silently fail if user is not authenticated
  end

  def render_unauthorized(message = 'Unauthorized')
    render json: { error: message }, status: :unauthorized
  end
end
