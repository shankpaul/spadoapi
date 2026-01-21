class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Enums
  enum :role, { admin: 0, agent: 1, sales_executive: 2, accountant: 3 }

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # Callbacks
  before_create :set_last_activity

  # Constants
  INACTIVITY_PERIOD = 30.days

  # Activity tracking
  def update_last_activity!
    update_column(:last_activity_at, Time.current)
    check_and_clear_expiration
  end

  def inactive?
    last_activity_at.nil? || last_activity_at < INACTIVITY_PERIOD.ago
  end

  def check_and_expire_if_inactive!
    if inactive?
      update_column(:expires_at, Time.current)
      true
    else
      false
    end
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  # Account locking
  def locked?
    access_locked?
  end

  def permanent_lock?
    locked_at.present? && expired?
  end

  def lock_account!
    lock_access!
  end

  def unlock_account!
    unlock_access!
  end

  # Authentication
  def self.authenticate_with_credentials(email, password)
    user = find_by(email: email&.downcase&.strip)
    return nil unless user

    # Check if account is locked
    return :locked if user.locked?

    # Check if account is expired
    return :expired if user.expired?

    # Authenticate password using Devise
    if user.valid_password?(password)
      user.update_last_activity!
      user
    else
      nil
    end
  end

  def active_for_authentication?
    super && !expired?
  end

  def inactive_message
    expired? ? :expired : super
  end

  private

  def set_last_activity
    self.last_activity_at ||= Time.current
  end

  def check_and_clear_expiration
    update_column(:expires_at, nil) if expires_at.present?
  end
end
