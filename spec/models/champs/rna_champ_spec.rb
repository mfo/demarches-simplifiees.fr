# frozen_string_literal: true

describe Champs::RNAChamp do
  let(:types_de_champ_public) { [{ type: :rna }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:) } }
  let(:value) { "W182736273" }

  def with_external_id(external_id)
    champ.tap do
      _1.external_id = external_id
    end
  end

  describe '#valid?' do
    it do
      expect(with_external_id(nil).validate(:champs_public_value)).to be_truthy
      expect(with_external_id("2736251627").validate(:champs_public_value)).to be_falsey
      expect(with_external_id("A172736283").validate(:champs_public_value)).to be_falsey
      expect(with_external_id("W1827362718").validate(:champs_public_value)).to be_falsey
      expect(with_external_id("W182736273").validate(:champs_public_value)).to be_truthy
    end

    it 'when invalid format, it contains only error message for invalid format' do
      champ = with_external_id("W1827362")
      champ.validate(:champs_public_value)
      expect(champ.errors.full_messages.join).to match(/doit commencer par un W majuscule suivi de 9 chiffres ou lettres. Exemple : W503726238/)
    end

    it 'when valid format, but no data, it contains only error message for not found' do
      champ = with_external_id("W182736273")
      error = ExternalDataException.new(reason: 'Not retryable', code: 404)
      champ.update_columns(external_state: 'external_error', fetch_external_data_exceptions: [error])
      champ.validate(:champs_public_value)
      expect(champ.errors.full_messages).to eq(["Le champ « Numéro RNA » Résultat introuvable. Vérifiez vos informations."])
    end
  end

  describe "#export" do
    context "with association title" do
      before do
        champ.update(data: { association_titre: "Super asso" })
      end

      it { expect(champ.type_de_champ.champ_value_for_export(champ)).to eq("W182736273 (Super asso)") }
    end

    context "no association title" do
      it { expect(champ.type_de_champ.champ_value_for_export(champ)).to eq("W182736273") }
    end
  end
end
