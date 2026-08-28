# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe Ami::RecipientFcHash do
  describe '.call' do
    let(:user) { create(:user) }

    # Chaque fixture est la copie conforme du jeu de test fourni par AMI :
    # mêmes données pivot, seule la colonne `hash` change de version.
    def expect_hashes_matching(fixture)
      rows = CSV.read(Rails.root.join('spec/fixtures/files/ami', fixture), headers: true)

      rows.each do |row|
        fc_information = instance_double(
          FranceConnectInformation.name,
          given_name: row.fetch('prenoms'),
          family_name: row.fetch('nomDeNaissance'),
          birthdate: row.fetch('dateDeNaissance'),
          gender: row.fetch('genre'),
          birthplace: row.fetch('codePostalLieuDeNaissance'),
          birthcountry: row.fetch('codePaysDeNaissance')
        )
        fc_association = double('FranceConnectInformationAssociation', order: [fc_information])
        allow(user).to receive(:france_connect_informations).and_return(fc_association)

        computed_hash = described_class.call(user)
        expect(computed_hash).to eq(row.fetch('hash')),
          "row id=#{row.fetch('id')} does not match #{computed_hash} != #{row.fetch('hash')}"
      end
    end

    context 'when :ami_recipient_fc_hash_v2 is disabled' do
      it 'matches expected v1 hashes from the CSV fixture' do
        expect_hashes_matching('fc_recepient_hashes.csv')
      end
    end

    context 'when :ami_recipient_fc_hash_v2 is enabled' do
      before { Flipper.enable(:ami_recipient_fc_hash_v2) }

      it 'matches expected v2 hashes from the CSV fixture' do
        expect_hashes_matching('fc_recepient_hashes_v2.csv')
      end
    end
  end
end
