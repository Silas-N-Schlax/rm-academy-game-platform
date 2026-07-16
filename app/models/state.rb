class State
  def self.data
    Data.define(:id, :name, :country_id) do
      include DataFor::Model
      config :countries, project: -> { it.pluck(:states).flatten }
    end
  end
end
