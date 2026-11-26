# frozen_string_literal: true

# Once #14704 deploys, the editor writes the tree and no longer the
# coordinates. This code, still running until every process restarts,
# would rebuild the tree from them: its edits are frozen meanwhile.
describe RevisionEditConcern do
  describe 'an edit while #14704 deploys' do
    let(:procedure) { create(:procedure, :published, public_type_de_champs: [{ libelle: 'Nom' }, { libelle: 'Prénom' }]) }
    let(:draft) { procedure.draft_revision }
    let!(:siret) { draft.add_type_de_champ(type_champ: :text, libelle: 'SIRET', after_stable_id: draft.public_root_type_de_champs.last.stable_id) }

    def libelles(revision) = ProcedureRevision.find(revision.id).public_root_type_de_champs.map(&:libelle)

    before { Flipper.enable(:type_de_champ_tree_edit_frozen) }

    # a draft #14704 made: published, cloned or created after it deploys
    context 'on a draft without any coordinate' do
      before { ProcedureRevisionTypeDeChamp.where(revision: draft).delete_all }

      it 'is refused, the draft left as it is' do
        expect { draft.update_type_de_champ(draft.find_and_ensure_exclusive_use(siret.stable_id), libelle: 'Numéro SIRET') }
          .to raise_error(RevisionEditConcern::EditFrozenError)
        expect { draft.add_type_de_champ(type_champ: :text, libelle: 'Raison sociale') }
          .to raise_error(RevisionEditConcern::EditFrozenError)

        expect(libelles(draft)).to eq(['Nom', 'Prénom', 'SIRET'])
      end
    end

    # a draft #14704 edited: SIRET added since it deploys
    context 'on a draft with a type de champ added on its tree only' do
      before { ProcedureRevisionTypeDeChamp.where(revision: draft, type_de_champ: siret).delete_all }

      it 'is refused, the draft left as it is' do
        expect { draft.update_type_de_champ(draft.find_and_ensure_exclusive_use(siret.stable_id), libelle: 'Numéro SIRET') }
          .to raise_error(RevisionEditConcern::EditFrozenError)

        expect(libelles(draft)).to eq(['Nom', 'Prénom', 'SIRET'])
      end

      it 'refuses the publication, the type de champ kept' do
        expect { procedure.publish_or_reopen!(procedure.administrateurs.first, procedure.path) }
          .to raise_error(RevisionEditConcern::EditFrozenError)

        expect(procedure.reload.draft_revision).to eq(draft)
        expect(libelles(draft)).to eq(['Nom', 'Prénom', 'SIRET'])
        expect(TypeDeChamp.exists?(siret.id)).to be(true)
      end
    end
  end
end
