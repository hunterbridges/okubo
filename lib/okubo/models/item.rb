module Okubo
  class Item < ActiveRecord::Base
    self.table_name = "okubo_items"
    belongs_to :deck
    belongs_to :source, :polymorphic => true
    scope :untested, lambda{where(["box = ? and last_reviewed is null", 0])}
    scope :failed, lambda{where(["box = ? and last_reviewed is not null", 0])}
    scope :known, lambda{where(["box > ? and next_review > ?", 0, Time.now])}
    scope :expired, lambda{where(["box > ? and next_review <= ?", 0, Time.now])}

    DELAYS = [
      5.minutes, # Apprentice
      4.hours,
      1.day,
      3.days,    # Guru
      7.days,
      14.days,   # Master
      30.days,   # Enlighten
      60.days,
      120.days,
      240.days   # Burned
    ]

    LEVELS = {
      apprentice: "Apprentice",
      guru: "Guru",
      master: "Master",
      enlighten: "Enlighten",
      burned: "Burned"
    }

    def level
      return :apprentice if self[:box] < 3
      return :guru if self[:box] < 5
      return :master if self[:box] < 6
      return :enlighten if self[:box] < 9
      return :burned
    end

    def display_level
      LEVELS[self.level]
    end

    def right!
      self[:box] += 1
      self.times_right += 1
      self.last_reviewed = Time.now
      self.next_review = last_reviewed + DELAYS[[DELAYS.count, box].min-1]
      self.save!
    end

    def wrong!
      self[:box] = 0
      self.times_wrong += 1
      self.last_reviewed = Time.now
      self.next_review = nil
      self.save!
    end
  end
end
