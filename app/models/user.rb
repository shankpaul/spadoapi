class User < ApplicationRecord
  acts_as_paranoid

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Associations
  belongs_to :office, optional: true
  has_many :attendances, foreign_key: :agent_id, dependent: :destroy
  has_many :end_of_day_logs, foreign_key: :agent_id, dependent: :destroy

  # ActiveStorage attachments
  has_one_attached :avatar

  # Enums
  enum :role, { admin: 0, agent: 1, sales_executive: 2, accountant: 3 }

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :home_latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :home_longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true }

  validate :validate_avatar_attachment

  # Callbacks
  before_create :set_last_activity
  after_save :sync_home_coordinates_from_office, if: :saved_change_to_office_id?

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

  # Home location
  def home_coordinates
    return nil unless home_latitude.present? && home_longitude.present?
    { latitude: home_latitude, longitude: home_longitude }
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

  def sync_home_coordinates_from_office
    # Only sync if home coordinates are null and office is assigned
    if office.present? && home_latitude.nil? && home_longitude.nil?
      update_columns(
        home_latitude: office.latitude,
        home_longitude: office.longitude
      )
    end
  end

  def validate_avatar_attachment
    if avatar.attached?
      unless avatar.content_type.in?(%w[image/jpeg image/jpg image/png image/gif])
        errors.add(:avatar, 'must be a JPEG, PNG, or GIF image')
      end
      
      if avatar.byte_size > 5.megabytes
        errors.add(:avatar, 'must be less than 5MB')
      end
    end
  end
end
