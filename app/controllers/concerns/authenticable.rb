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
    authenticate_user!
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render_unauthorized('Invalid or expired token')
  end

  def current_user
    @current_user ||= super
  end

  def track_user_activity
    current_user&.update_last_activity! if user_signed_in?
  end

  def render_unauthorized(message = 'Unauthorized')
    render json: { error: message }, status: :unauthorized
  end
end
