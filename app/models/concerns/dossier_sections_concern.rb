# frozen_string_literal: true

module DossierSectionsConcern
  extend ActiveSupport::Concern

  def sections_for(type_de_champ)
    @sections = Hash.new do |hash, parent|
      case parent
      when :public
        hash[parent] = revision.types_de_champ_public.filter(&:header_section?)
      when :private
        hash[parent] = revision.types_de_champ_private.filter(&:header_section?)
      else
        hash[parent] = revision.children_of(parent).filter(&:header_section?)
      end
    end
    @sections[revision.parent_of(type_de_champ) || (type_de_champ.public? ? :public : :private)]
  end

  def auto_numbering_section_headers_for?(type_de_champ)
    return false if type_de_champ.child?(revision)

    sections_for(type_de_champ)&.none? { _1.libelle =~ /^\d/ }
  end

  def index_for_section_header(type_de_champ)
    types_de_champ = type_de_champ.private? ? revision.types_de_champ_private : revision.types_de_champ_public
    counters = []

    types_de_champ.each do |tdc|
      if tdc.repetition?
        index_in_repetition = revision.children_of(tdc).find_index { _1.stable_id == type_de_champ.stable_id }
        return "#{counters.first || 1}.#{index_in_repetition + 1}" if index_in_repetition
        next
      end

      next unless tdc.header_section?
      next unless project_champ(tdc).visible?

      level = tdc.level_for_revision(revision)
      counters = counters.first(level)
      counters[level - 1] = (counters[level - 1] || 0) + 1
      (0...level).each { |i| counters[i] ||= 1 }

      return counters.join('.') if tdc.stable_id == type_de_champ.stable_id
    end

    counters.join('.')
  end
end
