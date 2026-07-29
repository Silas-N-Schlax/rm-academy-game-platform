module PerPageClampable
  extend ActiveSupport::Concern

  class_methods do
    def clamp_per_page(value)
      return self::DEFAULT_PER_PAGE if value.blank?
      value.to_i.clamp(self::PER_PAGE_OPTIONS.min, self::PER_PAGE_OPTIONS.max)
    end
  end
end
