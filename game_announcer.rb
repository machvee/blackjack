module Blackjack
  class GameAnnouncer
    #
    # output a brief status to STDOUT to inform a view of play information
    # sub-class this to show alternate output (e.g. SilentGameAnnouncer)
    #
    attr_reader  :table
    attr_reader  :dealer

    def initialize(table, options={})
      @table = table
      @dealer = table.dealer
    end

    def overview
    end

    def dealer_hand_status
    end

    def player_hand_status(bet_box, decision, opt_bet_amt=nil)
    end

    def hand_outcome(hand, action, amount=nil)
    end

    def play_by_play(step, player, response)
    end

    def says(msg)
    end
  end

  class StdoutGameAnnouncer < GameAnnouncer
    def overview
      remaining = table.shoe.remaining_until_shuffle
      marker_status = if remaining.nil?
        ""
      elsif remaining == 0
        "at marker card"
      elsif remaining > 0
        " #{remaining} cards remain"
      else
        " #{remaining.abs} cards beyond"
      end

      tens_remaining = table.shoe.counts[10]
      ten_percentage = remaining == 0 ? "0.0" : (100.0 * (tens_remaining * 1.0)/remaining)

      says "#{table.name}: #{marker_status}, %5.1f%% tens" % ten_percentage

      table.each_player do |player|
        says "  #{player}"
      end
    end

    def dealer_hand_status
      if dealer.hand.flipped?
        bust_str = dealer.hand.bust? ? " BUST!" : ""
        says "Dealer has " + hand_val_str(dealer.hand) + bust_str
      else
        says "Hand #{table.rounds_played.count}: Dealer's showing %s %s" % [dealer.showing, dealer.hand]
      end
    end

    def player_hand_status(bet_box, decision=nil, opt_bet_amt=nil)
      says "%s %s %s%s" % [
        bet_box.player_name,
        decision.nil? ? "has" : DECISIONS[decision],
        opt_bet_amt.nil? ? "" : "for $#{opt_bet_amt} : ",
        hand_val_str(bet_box.hand, bet_box.from_split?)
      ]
    end

    def hand_outcome(bet_box, outcome, amount=nil)
      msg = case outcome
        when Outcome::WON
          "%s WINS +$%d" % [bet_box.player_name, amount]
        when Outcome::LOST
          "%s LOST -$%d" % [bet_box.player_name, amount]
        when Outcome::INSURANCE_WON
          "%s WINS INSURANCE +$%d" % [bet_box.player_name, amount]
        when Outcome::INSURANCE_LOST
          "%s LOST INSURANCE -$%d" % [bet_box.player_name, amount]
        when Outcome::PUSH
          "%s PUSH" % [bet_box.player_name]
        when Outcome::BUST
          "%s HITS %s, and BUSTS -$%d" % [
            bet_box.player_name,
                   hand_val_str(bet_box.hand, bet_box.from_split?),
                                  amount]
        when Outcome::NONE
          nil
      end
      says msg
    end

    def play_by_play(step, player, response)
      msg = case step
        when :num_bets
          case response
            when Action::SIT_OUT
              "%s SITS OUT" % player.name
            else
              nil
          end
        when :bet_amount
          "%s BETS $%d" % [player.name, response]
        when :insurance
          case response
            when Action::NO_INSURANCE
              "%s says NO INSURANCE" % player.name
            when Action::EVEN_MONEY
              "%s has Blackjack and takes EVEN MONEY" % player.name
            else
              nil
          end
        when :insurance_bet_amount
           "%s takes INSURANCE for $%d" % [player.name, response]
        else
          nil
      end
      says msg
    end

    def says(msg)
      printer msg unless msg.nil?
    end

    private

    def printer(msg)
      puts "==> " + msg
    end

    def hand_val_str(hand, from_split=false)
      if hand.blackjack? && !from_split
        "BLACKJACK!"
      elsif !hand.soft? || (hand.soft? && (hand.hard_sum == hand.soft_sum || hand.hard_sum >= 17))
        hand.hard_sum.to_s
      else
        "#{hand.soft_sum}/#{hand.hard_sum}"
      end + " #{hand}"
    end
  end

end
