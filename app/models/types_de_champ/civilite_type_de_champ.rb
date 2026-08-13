# frozen_string_literal: true

class TypesDeChamp::CiviliteTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def self.category = ETAT_CIVIL
  def self.column_type = :enum
end
