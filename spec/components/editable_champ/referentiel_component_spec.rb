# frozen_string_literal: true

require 'rails_helper'

describe EditableChamp::ReferentielComponent, type: :component do
  let(:public_type_de_champs) { [{ type: :referentiel, referentiel:, referentiel_mapping: {} }] }
  let(:procedure) { create(:procedure, public_type_de_champs:) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.root_champs_public.first }
  let(:form) do
    ActionView::Helpers::FormBuilder.new("dossier[champs_public_attributes]", champ, ActionController::Base.new.view_context, {})
  end

  let(:component) { described_class.new(form:, champ:) }
  subject { render_inline(component) }

  context 'when referentiel is nil' do
    let(:referentiel) { nil }

    it 'renders a disabled input without crashing' do
      expect(subject).to have_field(type: 'text', disabled: true)
    end

    it 'does not render the autocomplete combobox' do
      expect(subject).not_to have_selector('react-fragment')
    end
  end

  describe 'an annotation referentiel, locked until the dossier is en instruction' do
    let(:referentiel) { create(:api_referentiel, :exact_match) }
    let(:public_type_de_champs) { [{ type: :text, libelle: 'Nom', stable_id: 99 }] }
    let(:private_type_de_champs) do
      [{ type: :referentiel, referentiel:, referentiel_mapping: mapping }]
    end
    let(:procedure) { create(:procedure, public_type_de_champs:, private_type_de_champs:) }
    let(:champ) { dossier.root_champs_private.first }

    context 'when it prefills a public champ' do
      let(:mapping) { { "$.nom" => { prefill: "1", prefill_stable_id: 99, type: "string" } } }

      context 'on a dossier en construction' do
        let(:dossier) { create(:dossier, :en_construction, procedure:) }

        it 'disables the input, because the prefill would write a public champ on the main stream' do
          expect(subject).to have_field(type: 'text', disabled: true)
        end
      end

      context 'on a dossier en instruction' do
        let(:dossier) { create(:dossier, :en_instruction, procedure:) }

        it 'leaves the input editable' do
          expect(subject).to have_field(type: 'text', disabled: false)
        end
      end

      # check_valid_stream_on_write? ne lève que sur un dossier en construction :
      # verrouiller un dossier terminé empêcherait une saisie pourtant légale.
      context 'on a terminated dossier' do
        let(:dossier) { create(:dossier, :accepte, procedure:) }

        it 'leaves the input editable' do
          expect(subject).to have_field(type: 'text', disabled: false)
        end
      end

      # Le mode autocomplete propage le pré-remplissage dans la requête elle-même,
      # via le setter data= : il doit être verrouillé comme la correspondance exacte.
      context 'when the referentiel runs in autocomplete mode' do
        let(:referentiel) { create(:api_referentiel, :autocomplete) }
        let(:dossier) { create(:dossier, :en_construction, procedure:) }

        it 'disables the combobox' do
          expect(subject.to_html).to include('is_disabled&quot;:true')
        end
      end
    end

    # Le cas de non-régression : un référentiel privé qui ne préremplit que des
    # annotations n'écrit jamais de champ public, donc rien ne doit le verrouiller.
    context 'when it prefills only annotations' do
      let(:private_type_de_champs) do
        [
          { type: :referentiel, referentiel:, referentiel_mapping: mapping },
          { type: :text, libelle: 'Avis', stable_id: 77 },
        ]
      end
      let(:mapping) { { "$.avis" => { prefill: "1", prefill_stable_id: 77, type: "string" } } }
      let(:dossier) { create(:dossier, :en_construction, procedure:) }

      it 'leaves the input editable' do
        expect(subject).to have_field(type: 'text', disabled: false)
      end
    end
  end

  context 'when referentiel is present' do
    let(:referentiel) { create(:api_referentiel, :autocomplete) }

    it 'renders the autocomplete combobox' do
      expect(subject).to have_selector('react-fragment')
    end

    it 'includes dossier_id but no row_id in loader URL' do
      expect(subject.to_html).to include("dossier_id=#{dossier.id}")
      expect(subject.to_html).not_to include("row_id")
    end

    context 'when the champ is inside a repetition' do
      let(:public_type_de_champs) do
        [{ type: :repetition, stable_id: 100, children: [{ type: :referentiel, stable_id: 101, referentiel:, referentiel_mapping: {} }] }]
      end
      let(:dossier) { create(:dossier, procedure:) }
      let(:row_id) { dossier.repetition_add_row(dossier.find_type_de_champ_by_stable_id(100), updated_by: 'test') }
      let(:champ) do
        dossier.champ_for_update(dossier.find_type_de_champ_by_stable_id(101), row_id:, updated_by: 'test')
      end

      it 'includes the row_id in loader URL, so the API call resolves the champs of this row' do
        expect(subject.to_html).to include("row_id=#{row_id}")
      end
    end
  end
end
