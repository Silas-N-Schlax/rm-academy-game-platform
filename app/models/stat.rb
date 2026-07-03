class Stat
  def total_games(user)
    User.find_by(id: user.id).games.size
  end

  def total_wins(user)
    Player.where(user_id: user.id, winner: true).size
  end

  def total_losses(user)
    Player.where(user_id: user.id, winner: nil).size
  end

  def total_average(user)
    wins = total_wins(user)
    total = total_games(user)
    average(wins, total)
  end

  def total_games_by_game(user, type: "Go Fish")
    User.find_by(id: user.id).games.where(game_type: type).size
  end

  def total_wins_by_game(user, type: "Go Fish")
    Player.where(user_id: user.id, winner: true).each  do |player|
      player.game.game_type == type
    end.size
  end

  def total_losses_by_game(user, type: "Go Fish")
    Player.where(user_id: user.id, winner: nil).each  do |player|
      player.game.game_type == type
    end.size
  end

  def total_average_by_game(user, type: "Go Fish")
    wins = total_wins_by_game(user, type: type)
    total = total_games_by_game(user, type: type)
    average(wins, total)
  end

  private

  def average(wins, total)
    return 0.0 if total.zero?

    (wins.to_f / total) * 100
  end
end
