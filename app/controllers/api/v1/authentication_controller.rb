class Api::V1::AuthenticationController < ApplicationController
  skip_before_action :track_user_activity, only: [:login]
  respond_to :json

  # POST /api/v1/auth/login
  def login
    @user = User.find_by(email: login_params[:email])
    
    if @user&.valid_for_authentication? { @user.valid_password?(login_params[:password]) }
      if @user.active_for_authentication?
        @user.update_last_activity!
        @message = 'Login successful'
        
        # Generate JWT token manually
        token = generate_jwt_token(@user)
        response.headers['Authorization'] = "Bearer #{token}"
        
        render :login, status: :ok
      else
        render json: { 
          error: @user.inactive_message == :expired ? 
                 'Account has expired due to inactivity. Please contact support.' :
                 'Account is inactive. Please contact support.'
        }, status: :forbidden
      end
    elsif @user&.access_locked?
      render json: { 
        error: 'Account is locked due to too many failed login attempts. Please try again later or contact support.' 
      }, status: :forbidden
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  # DELETE /api/v1/auth/logout
  def logout
    # JWT will be added to denylist automatically by devise-jwt
    render json: { message: 'Logged out successfully' }, status: :ok
  end

  # GET /api/v1/auth/me
  def me
    authenticate_request!
    @user = current_user
    render :me, status: :ok
  end

  private

  def generate_jwt_token(user)
    JWT.encode(
      {
        sub: user.id,
        scp: 'user',
        aud: 'JWT_AUD',
        iat: Time.current.to_i,
        exp: 30.days.from_now.to_i,
        jti: SecureRandom.uuid
      },
      Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end

  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def login_params
    params.permit(:email, :password)
  end
end
