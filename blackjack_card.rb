require 'cards'

module Blackjack
  class Cards::Card
    #
    # monkey patch Card to have alternate Blackjack face values
    #
    ACE_SOFT_VALUE=1
    ACE_HARD_VALUE=11

    def face_value
      soft_value
    end

    def soft_value
      Cards::Card.custom_value_of_face(face)
    end

    def hard_value
      case face
        when ACE
          ACE_HARD_VALUE
        else
          face_value
      end
    end

    def self.custom_value_of_face(card_face)
      case card_face
        when ACE
          ACE_SOFT_VALUE
        when *FACE_CARDS
          Cards::Card.face_to_value(TEN)
        else
          Cards::Card.face_to_value(card_face)
      end
    end

    def ten?
      Cards::Card.custom_value_of_face(face) == 10
    end
  end

  class Cards::Cards
    #
    # monkey patch Cards to have builtin knowledge of blackjack
    # hands sums and states
    #
    TWENTYONE = 21

    def blackjack?
      length == 2 && hard_sum == TWENTYONE
    end

    def bust?
      soft_sum > TWENTYONE 
    end

    def hittable?
      soft_sum < TWENTYONE 
    end

    def soft?
      has_ace?
    end

    def has_ace?
      any? {|c| c.ace?}
    end

    def pair?
      length == 2 && (cards[0].hard_value == cards[1].hard_value)
    end

    def hard_sum
      return soft_sum if bust?

      #
      # Only one Card::ACE uses the soft value, the rest are taken as hard_value
      #
      first_ace = true
      inject(0) do |t, c|
        t += if c.ace? && first_ace
          first_ace = false
          c.hard_value
        else
          c.soft_value
        end
      end
    end

    def soft_sum
      inject(0) {|t, c| t += c.soft_value}
    end

    def counts
      #
      # return [[face, count_in_deck, face_val, count_in_deck]]
      #
      freq = Hash[Card::FACES.map{|f| Cards::Card.custom_value_of_face(f)}.uniq.zip([0]*Card::FACES.length)]
      map {|c| freq[c.face_value] += 1}
      freq.to_a
    end
  end
end
