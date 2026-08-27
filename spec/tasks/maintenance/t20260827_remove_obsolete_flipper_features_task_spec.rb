# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260827RemoveObsoleteFlipperFeaturesTask do
    let(:features) { Flipper::Adapters::ActiveRecord::Feature }
    let(:gates) { Flipper::Adapters::ActiveRecord::Gate }

    # En test l'adaptateur configuré est Flipper::Adapters::Memory, qui n'écrit
    # rien en base. On bascule sur l'adaptateur ActiveRecord pour exercer le
    # chemin réel de production. La bascule doit se faire dans un before et non
    # un around : l'instance Flipper est initialisée paresseusement, et une
    # affectation trop précoce est écrasée.
    before do
      @previous_flipper = Flipper.instance
      Flipper.instance = Flipper.new(Flipper::Adapters::ActiveRecord.new)
    end

    after { Flipper.instance = @previous_flipper }

    describe "the list itself" do
      it 'never targets a flag the code still declares' do
        declared = Rails.root.join('config/initializers/flipper.rb').read
          .scan(/^\s*:(\w+),?\s*$/).flatten

        expect(described_class::OBSOLETE_FEATURES.map(&:to_s) & declared).to be_empty
      end
    end

    describe "#process" do
      subject(:process) { described_class::OBSOLETE_FEATURES.each { described_class.process(it) } }

      it 'removes every obsolete row' do
        described_class::OBSOLETE_FEATURES.each { Flipper.add(it) }

        expect { process }
          .to change { features.where(key: described_class::OBSOLETE_FEATURES.map(&:to_s)).count }
          .from(described_class::OBSOLETE_FEATURES.size).to(0)
      end

      it 'removes the gates left behind by fully-enabled flags' do
        Flipper.enable(:api_entreprise_tva_job)
        Flipper.enable_actor(:ocr, users.usager)

        expect { process }
          .to change { gates.where(feature_key: ['api_entreprise_tva_job', 'ocr']).count }.to(0)
      end

      it 'leaves the flags still in use alone' do
        Flipper.add(:switch_domain)
        Flipper.enable(:switch_domain)

        expect { process }.not_to change { features.where(key: 'switch_domain').count }
        expect(Flipper.enabled?(:switch_domain)).to be true
      end

      it 'is idempotent: a key already absent is not an error' do
        expect { process }.not_to raise_error
        expect { process }.not_to raise_error
      end
    end
  end
end
