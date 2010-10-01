module Cash
  module Finders
    def self.included(active_record_class)
      active_record_class.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def self.extended(active_record_class)
        class << active_record_class
          alias_method_chain :relation, :cache
        end
      end

      def relation_with_cache #:nodoc:
        @relation ||= ActiveRecord::Relation.new(self, arel_table)
        @relation.is_cached = true
        relation_without_cache
      end

      def without_cache(&block)
        with_scope(:find => {:readonly => true}, &block)
      end

      # User.find(:first, ...), User.find_by_foo(...), User.find(:all, ...), User.find_all_by_foo(...)
      def find_with_cache(options)
        Query::Select.perform(self, options, scope(:find))
      end

      def find_every_without_cache(*args)
        find_without_cache(:all, *args)
      end
      
      def find_without_cache(*args)
        find(*args)
      end
      
      # User.find(1), User.find(1, 2, 3), User.find([1, 2, 3]), User.find([])
      def find_from_ids_with_cache(ids, options)
        Query::PrimaryKey.perform(self, ids, options, scope(:find))
      end

      # User.count(:all), User.count, User.sum(...)
      def calculate_with_cache(operation, column_name, options = {})
        Query::Calculation.perform(self, operation, column_name, options, scope(:find))
      end
      
      def calculate_without_cache(*args)
        calculate(*args)
      end
    end
  end
end
