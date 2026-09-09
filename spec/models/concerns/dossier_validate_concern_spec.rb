# frozen_string_literal: true

describe DossierValidateConcern do
  describe "#champs_public_valid?" do
    include Logic

    let(:procedure) { create(:procedure, public_type_de_champs: type_de_champs) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:type_de_champs) { [type_de_champ].compact }
    let(:type_de_champ) { nil }
    let(:errors) { dossier.champs_public_valid?; dossier.errors }

    it 'no mandatory champs' do
      expect(errors).to be_empty
    end

    context "with mandatory champs" do
      let(:type_de_champ) { { mandatory: true } }
      let(:champ_with_error) { dossier.champ_data.first }

      before do
        champ_with_error.value = nil
        champ_with_error.save
      end

      it 'should have errors' do
        expect(errors).not_to be_empty
        expect(errors.first.full_message).to eq("Le champ « Value » doit être rempli")
      end

      context "conditionaly visible" do
        let(:type_de_champs) { [{ type: :yes_no, stable_id: 99, mandatory: false }, type_de_champ] }
        let(:type_de_champ) { { mandatory: true, condition: ds_eq(champ_value(99), constant(true)) } }

        it 'should not have errors' do
          expect(errors).to be_empty
        end
      end
    end

    context "with mandatory SIRET champ" do
      let(:type_de_champ) { { type: :siret, mandatory: true } }
      let(:champ_siret) { dossier.champ_data.first }

      before do
        champ_siret.update(value: '44011762001530')
      end

      it 'should not have errors' do
        expect(errors).to be_empty
      end

      context "and invalid SIRET" do
        before do
          champ_siret.update(value: "1234")
          dossier.reload
        end

        it 'should have errors' do
          expect(errors).not_to be_empty
          expect(errors.first.full_message).to eq("Le champ « Value » doit être rempli")
        end
      end
    end

    context "with champ repetition" do
      let(:type_de_champ) { { type: :repetition, mandatory: true, children: [{ mandatory: true }] } }
      let(:revision) { procedure.active_revision }
      let(:type_de_champ_repetition) { revision.type_de_champs.first }

      context "when no champs" do
        it 'should have errors' do
          dossier.champ_data.first.row_ids.each do |row_id|
            dossier.repetition_remove_row(type_de_champ_repetition, row_id, updated_by: 'test')
          end
          expect(dossier.champ_data.first.rows).to be_empty
          expect(errors).not_to be_empty
          expect(errors.first.full_message).to eq("Le champ « Value » doit être rempli")
        end
      end

      context "when mandatory champ inside repetition" do
        it 'should have errors' do
          expect(dossier.champ_data.first.rows).not_to be_empty
          expect(errors).not_to be_empty
          expect(errors.first.full_message).to eq("Le champ « Value » doit être rempli")
        end

        context "conditionaly visible" do
          let(:type_de_champs) { [{ type: :yes_no, stable_id: 99, mandatory: false }, type_de_champ] }
          let(:type_de_champ) { { type: :repetition, mandatory: true, children: [{ mandatory: true }], condition: ds_eq(champ_value(99), constant(true)) } }

          it 'should not have errors' do
            expect(dossier.champ_data.second.rows).not_to be_empty
            expect(errors).to be_empty
          end

          it 'should have errors' do
            dossier.champ_data.first.update(value: 'true')
            expect(dossier.champ_data.second.rows).not_to be_empty
            expect(errors).not_to be_empty
            expect(errors.first.full_message).to eq("Le champ « Value » doit être rempli")
          end
        end
      end
    end
  end
end
