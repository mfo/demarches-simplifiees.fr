# frozen_string_literal: true

Administrate::Engine.add_stylesheet('manager.css')

require "administrate/order"

# When sorting a has_many column by its associated records count, Administrate's
# `Order#order_by_count` adds a `GROUP BY <table>.id`. Grouping by the primary key
# lets PostgreSQL select the other columns of that table, but not the columns of a
# joined table. Models whose default scope carries an `eager_load` (Administrateur,
# Instructeur eager loading their user) therefore select `users.*`, which is absent
# from the GROUP BY, raising PG::GroupingError. Dropping the eager loading from the
# aggregate query fixes it; the displayed associations are re-included afterwards by
# Administrate through the dashboard's `collection_includes`.
module Administrate
  class Order
    module EagerLoadCompatibleCount
      private

      def order_by_count(relation)
        super(relation.unscope(:eager_load))
      end
    end

    prepend EagerLoadCompatibleCount
  end
end
