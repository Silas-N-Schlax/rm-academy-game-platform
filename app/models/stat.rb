class Stat < ApplicationRecord
  self.primary_key = "id"
  self.inheritance_column = nil

  def self.for(user)
    where(user_id: user.id)
  end
end
