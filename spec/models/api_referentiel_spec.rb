# frozen_string_literal: true

require 'rails_helper'

describe Referentiels::APIReferentiel, type: :model do
  let(:authentication_data) { { "header" => 'Authorization', "value" => 'Bearer secret' } }
  it 'encrypts authentication_data' do
    referentiel = described_class.create!(name: SecureRandom.uuid, url: 'https://api.gouv.fr', authentication_data:, mode: :autocomplete, test_data: "kkk", use_tiptap: false)

    referentiel.reload
    expect(referentiel.authentication_data).to eq(authentication_data)
    expect(Referentiel.where(id: referentiel.id).pluck(:authentication_data)).not_to include("Authorization")
  end

  describe '#tiptap_mention_stable_ids' do
    let(:referentiel) { build(:api_referentiel, :exact_match, url_tiptap:) }

    context 'when url_tiptap is nil' do
      let(:url_tiptap) { nil }
      it { expect(referentiel.tiptap_mention_stable_ids).to eq([]) }
    end

    context 'with one tdc mention' do
      let(:url_tiptap) { { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "https://api.gouv.fr/" }, { "type" => "mention", "attrs" => { "id" => "tdc42", "label" => "Dep" } }] }] } }
      it { expect(referentiel.tiptap_mention_stable_ids).to eq([42]) }
    end

    context 'with {query} and tdc mentions' do
      let(:url_tiptap) { { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "mention", "attrs" => { "id" => "{query}", "label" => "Query" } }, { "type" => "mention", "attrs" => { "id" => "tdc42", "label" => "Dep" } }, { "type" => "mention", "attrs" => { "id" => "tdc57", "label" => "Code" } }] }] } }
      it { expect(referentiel.tiptap_mention_stable_ids).to eq([42, 57]) }
    end
  end

  describe '#url_has_query_tag?' do
    let(:referentiel) { build(:api_referentiel, :exact_match, url_tiptap:) }

    context 'with {query} tag' do
      let(:url_tiptap) { { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "mention", "attrs" => { "id" => "{query}", "label" => "Query" } }] }] } }
      it { expect(referentiel.url_has_query_tag?).to be true }
    end

    context 'without {query} tag' do
      let(:url_tiptap) { { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "https://api.gouv.fr/" }] }] } }
      it { expect(referentiel.url_has_query_tag?).to be false }
    end

    context 'when url_tiptap is nil' do
      let(:url_tiptap) { nil }
      it { expect(referentiel.url_has_query_tag?).to be false }
    end
  end
end
