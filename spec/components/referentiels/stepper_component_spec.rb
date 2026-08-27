# frozen_string_literal: true

RSpec.describe Referentiels::StepperComponent, type: :component do
  let(:referentiel) { create(:api_referentiel, :exact_match) }
  let(:procedure) { create(:procedure, public_type_de_champs:, private_type_de_champs:) }
  let(:public_type_de_champs) { [] }
  let(:private_type_de_champs) { [] }
  let(:step_component) do
    Referentiels::MappingFormComponent.new(
      referentiel:,
      type_de_champ:,
      procedure:
    )
  end

  subject(:rendered_component) { render_inline(described_class.new(step_component:)) }

  context 'when referentiel is private' do
    let(:type_de_champ) { procedure.draft_revision.private_root_type_de_champs.first }
    let(:private_type_de_champs) { [{ type: :referentiel, referentiel: }] }

    it 'back links goes to annotations' do
      expect(rendered_component)
        .to have_link('Annotations privées', href: Rails.application.routes.url_helpers.annotations_admin_procedure_path(procedure))
    end
  end

  context 'when referentiel is public' do
    let(:type_de_champ) { procedure.draft_revision.public_root_type_de_champs.first }
    let(:public_type_de_champs) { [{ type: :referentiel, referentiel: }] }

    it 'back links goes to champs' do
      expect(rendered_component)
        .to have_link('Champs du formulaire', href: Rails.application.routes.url_helpers.champs_admin_procedure_path(procedure))
    end
  end
end
