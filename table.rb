require 'counter_measures'
require 'blackjack_card'
require 'shoe'
require 'strategy_validator'
require 'dealer'
require 'player'
require 'player_hand_strategy'
require 'player_stats'
require 'bet_boxes'
require 'bet_box'
require 'bank'
require 'game_play'

module Blackjack
  class Table

    include CounterMeasures

    counters :players_seated

    DEFAULT_HOUSE_BANK_AMOUNT=250_000

    DEFAULT_MAX_SEATS = 6
    DEFAULT_BLACKJACK_PAYS = [3,2]

    DEFAULT_CONFIG = {
      blackjack_payout:    DEFAULT_BLACKJACK_PAYS,
      dealer_hits_soft_17: false,
      player_surrender:    false,
      double_down_on:      [], # ANY or -- [9,10,11]
      num_seats:           DEFAULT_MAX_SEATS,
      minimum_bet:         25,
      maximum_bet:         5000,
      max_player_bets:     3
    }

    attr_reader   :name
    attr_reader   :shoe
    attr_reader   :dealer
    attr_reader   :seated_players
    attr_reader   :bet_boxes
    attr_reader   :config
    attr_reader   :bank

    def initialize(name, options={})
      @name = name
      @config = DEFAULT_CONFIG.merge(options)
      @bank = Bank.new(DEFAULT_HOUSE_BANK_AMOUNT)
      @shoe = new_shoe
      @shoe.force_shuffle

      @seated_players = Array.new(num_seats) {nil}

      #
      # bet_boxes array 0 to (num_seats-1) are positions right to left
      # on the table.  Dealer deals to position 0 first and (num_seats-1)
      # last
      #
      @bet_boxes = BetBoxes.new(self, num_seats)

      @dealer = Dealer.new(self)
    end

    def join(player, desired_seat_position=nil)
      seat_position = find_empty_seat_position(desired_seat_position)
      if seat_position.nil?
        if desired_seat_position.nil?
          raise "Sorry this table is full"
        else
          raise "Sorry that seat is taken by #{seated_players[desired_seat_position].name}"
        end
      end
      seated_players[seat_position] = player
      players_seated.incr
      seat_position
    end

    def leave(player)
      ind = seated_players.index(player)
      raise "player #{player.name} isn't at table #{name}" if ind.nil?
      seated_players[ind] = nil
    end

    def seat_available?(desired_seat_position=nil)
      !find_empty_seat_position(desired_seat_position).nil?
    end

    def seat_position(player)
      seated_players.index(player)
    end

    def new_hand
      shoe.new_hand
    end

    def num_players
      seated_players.count {|sp| !sp.nil?}
    end

    def any_seated_players?
      !seated_players.compact.empty?
    end

    private

    def new_shoe
      config[:shoe] || SixDeckShoe.new
    end

    def num_seats
      config[:num_seats]
    end

    def find_empty_seat_position(desired_seat_position=nil)
      if desired_seat_position.nil?
        # find first available empty seat index, or nil of none
        seated_players.index(nil) 
      else
        seated_players[desired_seat_position].nil? ? desired_seat_position : nil
      end
    end
  end
end
