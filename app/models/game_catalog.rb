class GameCatalog
  def self.data
    Data.define(:id, :name, :description, :min_players, :max_players, :duration, :game_type, :logo, :sections) do
      include DataFor::Model
      config :games

      def to_param = id
    end
  end
end
