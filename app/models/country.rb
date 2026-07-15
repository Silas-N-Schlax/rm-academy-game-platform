class Country
  def self.data
    Data.define(:id, :name, :states) do
      include DataFor::Model
      config :countries
    end
  end
end
