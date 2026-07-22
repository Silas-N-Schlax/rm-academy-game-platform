class BoardPreviewController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    @board = mock_board
    render layout: "application_no_sidebar"
  end

  private

  def mock_board
    {
      name: "Friday Night Cards", game_type: "Rummy", stock_count: 21, turn_label: "Your Turn",
      your_name: "You", your_flag: "🇺🇸", discard_top: "8_of_diamonds", selected_label: "7♥ 8♥ 9♥",
      winner_name: "Alice", players: mock_players, melds: mock_melds, hand: mock_hand,
      feed: mock_feed, ranking: mock_ranking
    }
  end

  def mock_players
    [
      { name: "Alice", flag: "🇺🇸", melded: true, hand_size: 4, mini_hand: Array.new(4), overflow: 0 },
      { name: "Bob", flag: "🇬🇧", melded: false, hand_size: 5, mini_hand: Array.new(4), overflow: 1 },
      { name: "Cara", flag: "🇨🇦", melded: true, hand_size: 2, mini_hand: Array.new(2), overflow: 0 },
      { name: "Bartholomew Fitzgerald III", flag: "🇮🇪", melded: false, hand_size: 3, mini_hand: Array.new(3), overflow: 0 }
    ]
  end

  def mock_melds
    [
      %w[4_of_hearts 5_of_hearts 6_of_hearts],
      %w[queen_of_spades queen_of_hearts queen_of_diamonds],
      %w[2_of_clubs 2_of_diamonds 2_of_spades],
      %w[3_of_spades 3_of_hearts 3_of_diamonds],
      %w[9_of_clubs 10_of_clubs jack_of_clubs queen_of_clubs],
      %w[7_of_diamonds 8_of_diamonds 9_of_diamonds 10_of_diamonds]
    ]
  end

  def mock_hand
    active = %w[7_of_hearts 8_of_hearts 9_of_hearts]
    %w[3_of_spades 3_of_hearts 5_of_diamonds 7_of_hearts 8_of_hearts 9_of_hearts
       jack_of_clubs queen_of_spades king_of_diamonds ace_of_clubs].map do |card|
      { card: card, active: active.include?(card) }
    end
  end

  def mock_feed
    [
      { time: "Just now", text: "You drew from the discard pile." },
      { time: "1 min ago", text: "Cara laid down a meld: 3♠ 3♥ 3♦." },
      { time: "2 min ago", text: "Bob drew from the stock." },
      { time: "3 min ago", text: "Bob discarded 6♣." },
      { time: "4 min ago", text: "Alice laid off 10♦ onto an existing run." },
      { time: "5 min ago", text: "Alice laid down a meld: 4♥ 5♥ 6♥." }
    ]
  end

  def mock_ranking
    [
      { place: 2, name: "Cara", flag: "🇨🇦", pips: 6 },
      { place: 3, name: "You", flag: "🇺🇸", pips: 14 },
      { place: 4, name: "Bob", flag: "🇬🇧", pips: 27 }
    ]
  end
end
