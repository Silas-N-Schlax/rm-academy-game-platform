module ApplicationHelper
  NO_VALUE = "—"

  def formatted_duration(seconds)
    return NO_VALUE if seconds.blank? || seconds.zero?

    total_seconds = seconds.to_i
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    remaining_seconds = total_seconds % 60
    format("%02d:%02d:%02d", hours, minutes, remaining_seconds)
  end

  def formatted_percentage(value)
    return NO_VALUE if value.nil? || value.zero?

    "#{value.round(1)}%"
  end

  def formatted_count(value)
    return NO_VALUE if value.blank? || value.zero?

    value.to_s
  end
end
