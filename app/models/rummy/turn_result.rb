module Rummy
  class TurnResult
    attr_reader :current_player
    attr_accessor :draw_source, :card_drawn, :recycled_stock,
                  :melds_laid_down, :lay_offs, :card_discarded, :went_out

    NO_DRAW_MESSAGE = "had nothing to draw — stock and discard were both empty."
    RECYCLE_MESSAGE = "The stock ran out, so the discard pile (except its top card) was reshuffled into a new stock."

    def initialize(current_player:, draw_source: nil, card_drawn: nil, recycled_stock: false,
                    melds_laid_down: [], lay_offs: [], card_discarded: nil, went_out: false)
      @current_player = current_player
      @draw_source = draw_source
      @card_drawn = card_drawn
      @recycled_stock = recycled_stock
      @melds_laid_down = melds_laid_down
      @lay_offs = lay_offs
      @card_discarded = card_discarded
      @went_out = went_out
    end

    def feed_lines(viewer_id)
      [ draw_line(viewer_id), recycle_line, *meld_lines(viewer_id), *lay_off_lines(viewer_id),
        discard_line(viewer_id), went_out_line(viewer_id) ].compact
    end

    def as_json
      {
        "current_player" => current_player.as_json,
        "draw_source" => draw_source,
        "card_drawn" => card_drawn&.as_json,
        "recycled_stock" => recycled_stock,
        "melds_laid_down" => melds_laid_down.map(&:as_json),
        "lay_offs" => lay_offs.map { |lay_off| lay_off_as_json(lay_off) },
        "card_discarded" => card_discarded&.as_json,
        "went_out" => went_out
      }
    end

    def self.from_json(json)
      return if json.blank?
      new(**from_json_attributes(json))
    end

    def self.from_json_attributes(json)
      {
        current_player: Player.from_json(json["current_player"]),
        draw_source: json["draw_source"],
        card_drawn: Card.from_json(json["card_drawn"]),
        recycled_stock: json["recycled_stock"],
        melds_laid_down: json["melds_laid_down"].map { |meld| Meld.from_json(meld) },
        lay_offs: json["lay_offs"].map { |lay_off| lay_off_from_json(lay_off) },
        card_discarded: Card.from_json(json["card_discarded"]),
        went_out: json["went_out"]
      }
    end

    def self.lay_off_from_json(json)
      { meld: Meld.from_json(json["meld"]), cards: json["cards"].map { |card| Card.from_json(card) } }
    end

    private_class_method :from_json_attributes, :lay_off_from_json

    private

    def lay_off_as_json(lay_off)
      { "meld" => lay_off[:meld].as_json, "cards" => lay_off[:cards].map(&:as_json) }
    end

    def draw_line(viewer_id)
      return if draw_source.nil?
      return "#{who(viewer_id)} #{NO_DRAW_MESSAGE}" if draw_source == "none"
      return stock_draw_line(viewer_id) if draw_source == "stock"
      "#{who(viewer_id)} drew the #{card_description(card_drawn)} from the discard pile."
    end

    def stock_draw_line(viewer_id)
      return "You drew the #{card_description(card_drawn)} from the stock." if actor?(viewer_id)
      "#{current_player.name} drew a card from the stock."
    end

    def recycle_line
      RECYCLE_MESSAGE if recycled_stock
    end

    def meld_lines(viewer_id)
      melds_laid_down.map { |meld| "#{who(viewer_id)} melded #{meld_phrase(meld)}." }
    end

    def meld_phrase(meld)
      meld.group? ? meld.description : "a #{meld.description}"
    end

    def lay_off_lines(viewer_id)
      lay_offs.map { |lay_off| lay_off_line(viewer_id, lay_off) }
    end

    def lay_off_line(viewer_id, lay_off)
      cards_text = lay_off[:cards].map { |card| card_description(card) }.join(", ")
      "#{who(viewer_id)} laid off the #{cards_text} onto the #{lay_off[:meld].description}."
    end

    def discard_line(viewer_id)
      return if card_discarded.nil?
      "#{who(viewer_id)} discarded the #{card_description(card_discarded)}."
    end

    def went_out_line(viewer_id)
      return unless went_out
      "#{who(viewer_id)} went out and won the game!"
    end

    def who(viewer_id)
      actor?(viewer_id) ? "You" : current_player.name
    end

    def actor?(viewer_id)
      current_player.id == viewer_id
    end

    def card_description(card)
      "#{Card::SPELLED_RANKS[card.rank] || card.rank} of #{card.suit}"
    end
  end
end
