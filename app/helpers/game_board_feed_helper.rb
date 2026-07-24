# frozen_string_literal: true

module GameBoardFeedHelper
  CLIMAX_FEED_KINDS = [ :win, :climax ].freeze
  NOTABLE_FEED_KINDS = [ :meld, :lay_off, :notable ].freeze

  def feed_line_class(kind)
    return "feed-drawer__line--climax" if CLIMAX_FEED_KINDS.include?(kind)
    return "feed-drawer__line--notable" if NOTABLE_FEED_KINDS.include?(kind)
    nil
  end

  def feed_line_text(line)
    return "🏆 #{line[:text]}" if line[:kind] == :win
    line[:text]
  end
end
