# frozen_string_literal: true

describe RoutingRuleStatusesConcern do
  describe 'routing rule statuses management' do
    include Logic

    let(:admin) { create :administrateur }
    let(:procedure) { create(:procedure, :published, routing_enabled: true, administrateur: admin) }
    let(:stable_id) { procedure.published_revision.public_root_type_de_champs.last.stable_id }

    before do
      procedure.draft_revision.add_type_de_champ(
        type_champ: :drop_down_list,
        libelle: 'Ville',
        drop_down_options: ['Paris', 'Lyon', 'Marseille']
      )
      procedure.publish_revision!(admin)
    end

    describe '#update_all_groupes_rule_validity_status' do
      let!(:gi_valid) do
        create(:groupe_instructeur,
               procedure: procedure,
               routing_rule: ds_eq(champ_value(stable_id), constant('Paris')))
      end
      let(:unknown_stable_id) { procedure.published_revision.type_de_champs.map(&:stable_id).max + 1 }
      let!(:gi_invalid) do
        create(:groupe_instructeur,
               procedure: procedure,
               routing_rule: ds_eq(champ_value(unknown_stable_id), constant('Invalid')),
               valid_routing_rule: true)
      end

      it 'updates valid_routing_rule for all groupes instructeurs' do
        expect { procedure.update_all_groupes_rule_validity_status }
          .to change { gi_valid.reload.valid_routing_rule }.from(false).to(true)
          .and change { gi_invalid.reload.valid_routing_rule }.from(true).to(false)
      end
    end

    describe '#update_all_groupes_rule_unicity_status' do
      let!(:gi_unique) do
        create(:groupe_instructeur,
               procedure: procedure,
               routing_rule: ds_eq(champ_value(stable_id), constant('Paris')),
               unique_routing_rule: false)
      end
      let!(:gi_duplicate1) do
        create(:groupe_instructeur,
               procedure: procedure,
               routing_rule: ds_eq(champ_value(stable_id), constant('Lyon')),
               unique_routing_rule: true)
      end
      let!(:gi_duplicate2) do
        create(:groupe_instructeur,
               procedure: procedure,
               routing_rule: ds_eq(champ_value(stable_id), constant('Lyon')),
               unique_routing_rule: true)
      end
      let!(:gi_nil) do
        create(:groupe_instructeur,
               procedure: procedure,
               routing_rule: nil,
               unique_routing_rule: true)
      end

      it 'updates unique_routing_rule based on duplication and null status' do
        expect { procedure.update_all_groupes_rule_unicity_status }
          .to change { gi_unique.reload.unique_routing_rule }.from(false).to(true)
          .and change { gi_duplicate1.reload.unique_routing_rule }.from(true).to(false)
          .and change { gi_duplicate2.reload.unique_routing_rule }.from(true).to(false)
          .and change { gi_nil.reload.unique_routing_rule }.from(true).to(false)
      end
    end

    describe '#update_all_groupes_rule_statuses' do
      let!(:gi) do
        create(:groupe_instructeur,
               procedure: procedure,
               routing_rule: ds_eq(champ_value(stable_id), constant('Paris')))
      end

      it 'calls both validity and unicity status updates' do
        expect(procedure).to receive(:update_all_groupes_rule_validity_status).and_call_original
        expect(procedure).to receive(:update_all_groupes_rule_unicity_status).and_call_original

        procedure.update_all_groupes_rule_statuses
      end

      it 'updates both valid_routing_rule and unique_routing_rule' do
        expect { procedure.update_all_groupes_rule_statuses }
          .to change { gi.reload.valid_routing_rule }.from(false).to(true)
          .and change { gi.reload.unique_routing_rule }.from(false).to(true)
      end
    end
  end
end
