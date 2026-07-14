Rails.configuration.after_initialize do
  ActiveJob::Base && ActiveRecord::Base
end
