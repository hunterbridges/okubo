module Okubo
  class Deck < ActiveRecord::Base
    include Enumerable
    include Okubo::Base
    self.table_name = "okubo_decks"
    belongs_to :user, :polymorphic => true
    has_many :items, :class_name => "Okubo::Item", :dependent => :destroy

    def each(&block)
      _items.each do |item|
        if block_given?
          block.call item
        else
          yield item
        end
      end
    end

    def ==(other)
      _items == other
    end

    def _items
      source_class.find(self.items.pluck(:source_id))
    end

    def <<(source)
      raise ArgumentError.new("Word already in the stack") if include?(source)
      self.items << Okubo::Item.new(:deck => self, :source_id => source.id, :source_type => source.class.name)
    end

    def self.add_deck(user)
      create!(user)
    end

    def delete(source)
      item = Okubo::Item.new(:deck => self, :source_id => source.id, :source_type => source.class.name)
      item.destroy
    end

    def flatten(chunk_size, num_chunks, from=Time.now)
      # WARNING True ultimate coding ahead.
      max_t = from + chunk_size * num_chunks
      all_due = items.known.due_as_of(max_t).order('next_review ASC')

      list = all_due.all.to_a
      list.sort_by! do |item|
        next_review = item.next_review || from
        next_review
      end

      old_buckets = []
      (0...num_chunks).each do |i|
        old_buckets.push []
      end

      list.each do |item|
        next_review = item.next_review || from
        target_bucket = ((next_review - from) / chunk_size).round
        target_bucket = [[0, target_bucket].max, num_chunks - 1].min
        old_buckets[target_bucket].push item
      end

      nsublists = num_chunks
      sublists = []
      list.each_slice((list.size.to_f/nsublists).ceil) { |slice| sublists << slice }
      while sublists.count < num_chunks
        sublists.push []
      end

      new_buckets = sublists

      ActiveRecord::Base.transaction do
        (0...num_chunks).each do |i|
          new_bucket_idx = i
          new_buckets[i].each do |item|
            next_review = item.next_review || from
            old_bucket_idx = ((next_review - from) / chunk_size).round
            d = new_bucket_idx - old_bucket_idx
            new_time = next_review + (d * chunk_size)

            item.next_review = new_time
            item.save
          end
        end
      end
    end

    #
    # Returns a suggested word review sequence.
    #
    def review
      [:failed, :expired].inject([]) do |words, s|
        words += self.items.send(s).order('random()')
      end
    end

    def next
      word = nil
      [:failed, :expired].each do |category|
        word = self.items.send(category).order('random()').limit(1).first
        break if word
      end
      word
    end

    def last
      self.items.order('created_at desc').limit(1).first
    end

    def untested
      source_class.find(self.items.untested.pluck(:source_id))
    end

    def failed
      source_class.find(self.items.failed.pluck(:source_id))
    end

    def known
      source_class.find(self.items.known.pluck(:source_id))
    end

    def expired
      source_class.find(self.items.expired.pluck(:source_id))
    end

    def box(number)
      source_class.find(self.items.where(:box =>  number).pluck(:source_id))
    end

    def source_class
      user.deck_name.to_s.singularize.titleize.constantize
    end
  end
end
