require 'cards'

module Blackjack
  class Dealer

    include Cards

    attr_accessor   :hand
    attr_reader     :table

    def initialize(table)
      @table = table
    end

    def upcard
      hand[0]
    end

    def downcard
      hand[1]
    end

    def flip_down_card
      downcard.up if downcard.face_down?
    end

  end
end
