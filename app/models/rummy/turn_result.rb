module Rummy
  class TurnResult
    attr_reader :current_player
    attr_accessor :draw_source, :card_drawn, :recycled_stock,
                  :melds_laid_down, :lay_offs, :card_discarded, :went_out, :occurred_at

    NO_DRAW_MESSAGE = "Had nothing to draw — stock and discard were both empty"
    RECYCLE_MESSAGE = "The stock ran out, so the discard pile (except its top card) was reshuffled into a new stock"

    def initialize(current_player:, draw_source: nil, card_drawn: nil, recycled_stock: false,
                    melds_laid_down: [], lay_offs: [], card_discarded: nil, went_out: false, occurred_at: nil)
      @current_player = current_player
      @draw_source = draw_source
      @card_drawn = card_drawn
      @recycled_stock = recycled_stock
      @melds_laid_down = melds_laid_down
      @lay_offs = lay_offs
      @card_discarded = card_discarded
      @went_out = went_out
      @occurred_at = occurred_at
    end

    def feed_lines(viewer_id)
      [ draw_entry(viewer_id), recycle_entry, *meld_entries, *lay_off_entries,
        discard_entry, went_out_entry ].compact
    end

    def actor_label(viewer_id)
      actor?(viewer_id) ? "You" : current_player.name
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
        "went_out" => went_out,
        "occurred_at" => occurred_at&.iso8601
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
        went_out: json["went_out"],
        occurred_at: json["occurred_at"] && Time.zone.parse(json["occurred_at"])
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

    def draw_entry(viewer_id)
      return if draw_source.nil?
      return { text: NO_DRAW_MESSAGE, kind: :draw } if draw_source == "none"
      return stock_draw_entry(viewer_id) if draw_source == "stock"
      { text: "Drew the #{card_description(card_drawn)} from the discard pile", kind: :draw }
    end

    def stock_draw_entry(viewer_id)
      return { text: "Drew the #{card_description(card_drawn)} from the stock", kind: :draw } if actor?(viewer_id)
      { text: "Drew a card from the stock", kind: :draw }
    end

    def recycle_entry
      { text: RECYCLE_MESSAGE, kind: :recycle } if recycled_stock
    end

    def meld_entries
      melds_laid_down.map { |meld| { text: "Melded #{meld_phrase(meld)}", kind: :meld } }
    end

    def meld_phrase(meld)
      meld.group? ? meld.description : "a #{meld.description}"
    end

    def lay_off_entries
      lay_offs.map { |lay_off| lay_off_entry(lay_off) }
    end

    def lay_off_entry(lay_off)
      cards_text = lay_off[:cards].map { |card| card_description(card) }.join(", ")
      { text: "Laid off the #{cards_text} onto the #{lay_off[:meld].description}", kind: :lay_off }
    end

    def discard_entry
      return if card_discarded.nil?
      { text: "Discarded the #{card_description(card_discarded)}", kind: :discard }
    end

    def went_out_entry
      return unless went_out
      { text: "Went out and won the game!", kind: :win }
    end

    def actor?(viewer_id)
      current_player.id == viewer_id
    end

    def card_description(card)
      "#{Card::SPELLED_RANKS[card.rank] || card.rank} of #{card.suit}"
    end
  end
end
