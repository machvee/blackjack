require 'counter_measures'
require 'blackjack_card'
require 'shoe'
require 'strategy_validator'
require 'prompt_player_hand_strategy'
require 'command_prompter'
require 'player_hand_strategy'
require 'strategy_table'
require 'table_driven_strategy'
require 'split_boxes'
require 'bet_boxes'
require 'bet_box'
require 'bank'
require 'dealer'
require 'player_stats'
require 'player'
require 'game_play'
require 'game_announcer'

module Blackjack
  class Table

    include CounterMeasures

    counters :players_seated, :rounds_played

    DEFAULT_HOUSE_BANK_AMOUNT=250_000
    DEFAULT_MAX_SEATS = 6
    DEFAULT_SHOE_CLASS = SixDeckShoe

    DEFAULT_CONFIG = {
      num_seats:            DEFAULT_MAX_SEATS,
      blackjack_payout:     [3,2], #  or [6,5]
      dealer_hits_soft_17:  false,
      player_surrender:     false,
      double_down_on:       [], # [] means ANY. or [9,10,11] or [10,11]
      minimum_bet:          25,
      maximum_bet:          5000,
      max_player_bets:      3,
      max_player_splits:    nil, # nil unlimited or n: one hand split up to n times
      game_announcer_class: GameAnnouncer,
      shoe:                 nil  # pass in a custom from which to deal
    }

    attr_reader   :name
    attr_reader   :shoe
    attr_reader   :dealer
    attr_reader   :seated_players
    attr_reader   :bet_boxes
    attr_reader   :config
    attr_reader   :house
    attr_reader   :game_announcer

    def initialize(name, options={})
      @name = name
      @config = DEFAULT_CONFIG.merge(options)

      init_table
    end

    def run(options={})
      gp = GamePlay.new(self)
      gp.run(options)
    end

    def init_table
      @house = Bank.new(DEFAULT_HOUSE_BANK_AMOUNT)
      @shoe = new_shoe
      @seated_players = Array.new(num_seats) {nil}

      #
      # bet_boxes array 0 to (num_seats-1) are positions right to left
      # on the table.  Dealer deals to position 0 first and (num_seats-1)
      # last
      #
      @bet_boxes = BetBoxes.new(self, num_seats)
      @dealer = Dealer.new(self)
      @game_announcer = config[:game_announcer_class].new(self)
    end

    def reset
      init_table
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
      seat(seat_position, player)
      game_announcer.says("Hey %s! Welcome to %s. You're in seat %d" % [player.name, name, seat_position])
      seat_position
    end

    def seat(seat_position, player)
      seated_players[seat_position] = player
      bet_boxes[seat_position].dedicate_to(player)
      players_seated.incr
      seat_position
    end

    def leave(player)
      game_announcer.says("Goodbye #{player.name}, thanks for playing")

      ind = seated_players.index(player)
      raise "player #{player.name} isn't at table #{name}" if ind.nil?
      seated_players[ind] = nil
      bet_boxes[ind].player_leaves
      self
    end

    def other_hands(omit_bet_box)
      []
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

    def new_dealer_hand
      shoe.new_hand(DealerHand)
    end

    def has_split_limit?
      !config[:max_player_splits].nil?
    end

    def split_limit
      config[:max_player_splits]
    end

    def num_players
      seated_players.count {|sp| !sp.nil?}
    end

    def any_seated_players?
      !seated_players.compact.empty?
    end

    def each_player
      seated_players.each do |player|
        next if player.nil?
        yield player
      end
      self
    end

    def find_player(name)
      each_player do |player|
        return player if player.name == name
      end
      nil
    end

    def inspect
      name
    end

    private

    def new_shoe
      shoe = config[:shoe] || DEFAULT_SHOE_CLASS.new
      shoe.force_shuffle
      shoe
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

  class TableWithAnnouncer < Table
    def initialize(name, options={})
      super(name, options.merge(game_announcer_class: StdoutGameAnnouncer))
    end
  end
end
