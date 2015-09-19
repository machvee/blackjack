module Blackjack
  class HandStats
    include CounterMeasures

    attr_reader  :name
    attr_reader  :buckets

    counters :played, :won, :pushed, :lost, :busted, :blackjacks

    def initialize(name)
      @name = name
    end

    def reset
      reset_counters
      self
    end

    def print_stat(counter_name, counter_value=nil)
      value = counter_value||counters[counter_name]
      HandStats.format_stat(value, played.count)
    end

    def self.format_stat(value, total)
      total.zero? ? "          -      " : "%6d [%7.2f%%]" % [value, value/(total*1.0) * 100.0]
    end

    def none?
      counters.values.all?(&:zero?)
    end
  end
end