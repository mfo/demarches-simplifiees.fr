# frozen_string_literal: true

class TypesDeChamp::ReferentielTypeDeChamp < TypeDeChamp
  def self.category = REFERENTIEL_EXTERNE
  def self.option_keys = [:referentiel_mapping]

  store_accessor :options, :referentiel_mapping

  def prefillable? = referentiel_in_exact_match?

  def referentiel_in_exact_match? = referentiel.present? && referentiel.exact_match?

  def revision_diff_options
    {
      referentiel_url_tiptap: RevisionDiffValue.new(referentiel&.url_tiptap) { referentiel_url_as_text },
      referentiel_mode: referentiel&.mode,
      referentiel_hint: referentiel&.hint,
      referentiel_test_data_tiptap: RevisionDiffValue.new(referentiel&.test_data_tiptap) { referentiel&.test_data_tiptap&.values&.join(', ') },
      referentiel_mapping:,
    }
  end

  # The URL is a tiptap document whose mentions stand for query parameters.
  def referentiel_url_as_text
    return if referentiel&.url_tiptap.blank?

    # a non-empty substitutions hash makes the service render mentions as text
    substitutions = Hash.new { |_, id| id }.merge('{query}' => '{query}')
    TiptapService.new.to_texts_and_tags(referentiel.url_tiptap.deep_symbolize_keys, substitutions)
  end

  def safe_referentiel_mapping
    Hash(referentiel_mapping).with_indifferent_access
  end

  def referentiel_mapping_prefillable
    safe_referentiel_mapping.filter { |_jsonpath, mapping_opts| mapping_opts[:prefill] == "1" }
  end

  def referentiel_mapping_prefillable_with_stable_id
    referentiel_mapping_prefillable.filter { |_jsonpath, mapping_opts| mapping_opts[:prefill_stable_id].present? }
  end

  def referentiel_mapping_prefillable_stable_ids
    referentiel_mapping_prefillable_with_stable_id.map { |_jsonpath, mapping_opts| mapping_opts[:prefill_stable_id] }
  end

  def referentiel_mapping_displayable
    safe_referentiel_mapping.filter { |_jsonpath, mapping_opts| mapping_opts[:prefill] != "1" }
  end

  def referentiel_mapping_displayable_for_instructeur
    referentiel_mapping_displayable.filter { |_jsonpath, mapping| mapping[:display_instructeur] == "1" }
  end

  def referentiel_mapping_displayable_for_usager
    referentiel_mapping_displayable.filter { |_jsonpath, mapping| mapping[:display_usager] == "1" }
  end
end
