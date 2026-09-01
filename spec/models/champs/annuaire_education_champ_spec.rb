# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Champs::AnnuaireEducationChamp do
  include Dry::Monads[:result]

  describe '#fetch_external_data' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :annuaire_education }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champ_data.first }

    subject { champ.fetch_external_data }

    before do
      allow_any_instance_of(APIEducation::AnnuaireEducationAdapter).to receive(:to_params).and_return(params)
    end

    context 'when a record is found' do
      let(:params) { { 'nom_etablissement' => 'karrigel an ankou' } }

      it { is_expected.to eq(Success(data: params)) }
    end

    context 'when no record is found' do
      let(:params) { nil }

      it 'returns a non-retryable not found failure' do
        expect(subject).to be_failure
        expect(subject.failure[:retryable]).to eq(false)
        expect(subject.failure[:code]).to eq(404)
        expect(subject.failure[:error].message).to eq('NotFound')
      end
    end
  end

  describe '#update_external_data!' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :annuaire_education }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champ_data.first.tap { _1.update_column(:data, 'any data') } }
    subject { champ.send(:update_external_data!, data: data) }

    shared_examples "a data updater (without updating the value)" do |data|
      it do
        expect { subject }.to change { champ.reload.data }.to(data)
        expect { subject }.not_to change { champ.reload.value }
      end
    end

    context 'when data is nil' do
      let(:data) { nil }
      it_behaves_like "a data updater (without updating the value)", nil
    end

    context 'when data is empty' do
      let(:data) { '' }
      it_behaves_like "a data updater (without updating the value)", ''
    end

    context 'when data is consistent' do
      let(:data) {
        {
          'nom_etablissement' => "karrigel an ankou",
          'nom_commune' => 'kumun',
          'identifiant_de_l_etablissement' => '666667',
        }
      }
      it_behaves_like "a data updater (without updating the value)", {
        'nom_etablissement' => "karrigel an ankou",
        'nom_commune' => 'kumun',
        'identifiant_de_l_etablissement' => '666667',
      }
    end
  end
end
