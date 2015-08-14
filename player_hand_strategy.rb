module Blackjack

  module Action
    LEAVE=0
    SIT_OUT=1
    BET=2
    HIT=3
    STAND=4
    SPLIT=5
    DOUBLE_DOWN=6
    SURRENDER=7
    INSURANCE=8
    NO_INSURANCE=9
    EVEN_MONEY=10
  end

  module Outcome
    WON=1
    LOST=2
    PUSH=3
  end

  class PlayerHandStrategy
    #
    # base class for player strategy on how to play his hand. 
    # An example sub-class would be one that just prompts the
    # player at the command line for instructions on what to do.
    # The context passed are all the other players hands on the
    # table (if any) and the dealers up card
    #

    attr_reader  :table
    attr_reader  :player

    def initialize(table, player, options={})
      @table = player
      @player = player
    end

    def play?
      #
      # Invoked for available_for(player) bet_boxes which lets players make one or more bets
      # return Action::BET to put chips in the bet_box
      # return Action::SIT_OUT to not make a bet in the bet_box
      # return Action::LEAVE to take bets and leave table before next hand dealt
      #
    end

    def bet_amount
      #
      # override in sub-class to provide a whole dollar amount
      # to bet for the main opening bet.
      #
    end

    def insurance_bet_amount(bet_box)
      # The player may choose up to 1/2
      # the MAIN bet amount for INSURANCE
    end

    def double_down_bet_amount(bet_box)
      # The player may choose up to the full
      # MAIN bet amount for DOUBLE_DOWN
    end

    def insurance?(bet_box)
      #
      # override in sub-class to indicate:
      #
      # Action::INSURANCE - the player wants insurance against dealer Ace up-card
      # Action::NO_INSURANCE - willing to lose automatically if dealer has blackjack
      # Action::EVEN_MONEY - player_hand is blackjack, will take 1-1 immediate payout 
      #
    end

    def decision(bet_box, dealer_up_card, other_hands=[])
      #
      # override in subclass to decide what to do based on
      #   bet_box (hand and bet_amount)
      #   dealer_up_card
      #   other_hands
      #
      # valid responses:
      #
      #   Action::HIT
      #   Action::STAND
      #   Action::SPLIT
      #   Action::DOUBLE_DOWN
      #
    end

    def outcome(win_lose_push, dealer_hand)
      #
      # win_lose_push:
      #   Action::WON
      #   Action::LOST
      #   Action::PUSH
      #
      # dealer_hand:
      #  allow player to examine dealers hand
      #
      self
    end

    def error(strategy_step, message)
      #
      # Dealer will call this with a message string when/if the PlayerHandStrategy
      # would respond with something invalid during the above strategy_steps
      # and then invokes the offending method again
      #
      #  (e.g. :decision, :insurance, :bet_amount, or :play)
      #
      # e.g. raise "invalid entry for #{strategy_step}: #{message}"
      # 
      raise "#{strategy_step}: #{message}"
    end
  end
end
