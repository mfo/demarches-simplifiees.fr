# frozen_string_literal: true

module Maintenance
  class T20260826CleanTypeDeChampOptionsTask < MaintenanceTasks::Task
    # options accumulated keys foreign to their type — a textarea holding
    # drop_down_options, a carte holding a character_limit — because only the
    # publication cleaned them up. clean_options keeps the keys the type owns.

    def collection
      TypeDeChamp.type_champs.values
        .map { foreign_options_scope(it) }
        .reduce(:or)
    end

    def process(type_de_champ)
      type_de_champ.update_column(:options, type_de_champ.clean_options)
    end

    private

    def foreign_options_scope(type_champ)
      keys = TypeDeChamp.find_sti_class(type_champ).option_keys.map(&:to_s)
      scope = TypeDeChamp.where(type_champ:)

      return scope.where.not(options: {}) if keys.empty?

      scope.where("options - ARRAY[:keys]::text[] <> '{}'::jsonb", keys:)
    end
  end
end
