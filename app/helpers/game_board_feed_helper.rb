# frozen_string_literal: true

module GameBoardFeedHelper
  NOTABLE_FEED_KINDS = [ :meld, :lay_off ].freeze

  def feed_line_class(kind)
    return "feed-drawer__line--climax" if kind == :win
    return "feed-drawer__line--notable" if NOTABLE_FEED_KINDS.include?(kind)
    nil
  end

  def feed_line_text(line)
    return "🏆 #{line[:text]}" if line[:kind] == :win
    line[:text]
  end
end
