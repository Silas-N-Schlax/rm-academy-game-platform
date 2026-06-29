# frozen_string_literal: true

# Helper method that renders icons from your icon library of choice.
#
# Usage:
#   = icon('home', size: 'x-large', color: 'primary')
#   = flash_icon('notice', size: 'x-large', color: 'primary')
#
# The chosen icon library is lucide. This can be
# changed by rerunning the generator with a different --icon-library option.
#
# Run `bin/rails g rolemodel:optics:icons --help` for an up-to-date list of available libraries.
#
module IconHelper
  # size, additional_classes, color, hover_text
  def icon(name, **)
    LucideIconBuilder.new(name, **).build
  end

  # size, additional_classes, color, hover_text
  def flash_icon(type, **)
    LucideIconBuilder.flash_icon(type, **).build
  end
end
