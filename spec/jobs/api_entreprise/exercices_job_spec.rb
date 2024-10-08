# frozen_string_literal: true

RSpec.describe APIEntreprise::ExercicesJob, type: :job do
  let(:siret) { '41816609600051' }
  let(:procedure) { create(:procedure) }
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/exercices.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/dgfip\/etablissements\/#{siret}\/chiffres_affaires/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::ExercicesJob.new.perform(etablissement.id, procedure.id) }

  it 'updates etablissement' do
    subject
    ca_list = Etablissement.find(etablissement.id).exercices.map(&:ca)
    expect(ca_list).to contain_exactly('900001', '1900051')
  end
end
