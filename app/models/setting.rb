class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value_type, presence: true, inclusion: { in: %w[string integer decimal boolean json] }

  # Cache settings in memory for performance
  def self.cached_get(key)
    Rails.cache.fetch("setting:#{key}", expires_in: 1.hour) do
      find_by(key: key)&.parsed_value
    end
  end

  def self.get(key, default = nil)
    cached_get(key) || default
  end

  def self.set(key, value, value_type: 'string', description: nil)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.value_type = value_type
    setting.description = description if description
    setting.save!
    Rails.cache.delete("setting:#{key}")
    setting
  end

  def parsed_value
    case value_type
    when 'integer'
      value.to_i
    when 'decimal'
      value.to_f
    when 'boolean'
      ActiveModel::Type::Boolean.new.cast(value)
    when 'json'
      JSON.parse(value) rescue {}
    else
      value
    end
  end

  def self.gst_percentage
    get('gst_percentage', 18.0)
  end

  def self.booking_buffer_minutes
    get('booking_buffer_minutes', 30)
  end
end
