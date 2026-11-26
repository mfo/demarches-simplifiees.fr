# frozen_string_literal: true

# Once #14704 deploys, the editor writes the tree and no longer the
# coordinates. This code, still running until every process restarts,
# rebuilds the tree from the coordinates on every edit.
describe RevisionEditConcern do
  describe 'an edit of a draft whose coordinates no longer follow its tree' do
    let(:procedure) { create(:procedure, :published, public_type_de_champs: [{ libelle: 'Nom' }, { libelle: 'Prénom' }]) }
    let(:draft) { procedure.draft_revision }
    let!(:siret) { draft.add_type_de_champ(type_champ: :text, libelle: 'SIRET', after_stable_id: draft.public_root_type_de_champs.last.stable_id) }

    def libelles(revision) = ProcedureRevision.find(revision.id).public_root_type_de_champs.map(&:libelle)

    # a draft #14704 made: published, cloned or created after it deploys
    context 'without any coordinate' do
      before { ProcedureRevisionTypeDeChamp.where(revision: draft).delete_all }

      it 'empties the draft' do
        draft.update_type_de_champ(draft.find_and_ensure_exclusive_use(siret.stable_id), libelle: 'Numéro SIRET')

        expect(libelles(draft)).to be_empty
      end
    end

    # a draft #14704 edited: SIRET added since it deploys
    context 'with a type de champ added on its tree only' do
      before { ProcedureRevisionTypeDeChamp.where(revision: draft, type_de_champ: siret).delete_all }

      it 'drops it from the draft' do
        draft.update_type_de_champ(draft.find_and_ensure_exclusive_use(siret.stable_id), libelle: 'Numéro SIRET')

        expect(libelles(draft)).to eq(['Nom', 'Prénom'])
      end

      it 'publishes the draft without it, and destroys it' do
        procedure.publish_or_reopen!(procedure.administrateurs.first, procedure.path)

        expect(libelles(procedure.reload.published_revision)).to eq(['Nom', 'Prénom'])
        expect(TypeDeChamp.exists?(siret.id)).to be(false)
      end
    end
  end
end
