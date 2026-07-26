# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReferentielAutocompleteRenderService do
  let(:referentiel) { create(:api_referentiel, :autocomplete, datasource: '$.items') }
  let(:api_response) do
    {
      'items' => [
        { 'finess' => 'Tango', 'ej_rs' => 'Charlie' },
        { 'finess' => 'Bob', 'ej_rs' => 'Delta' },
      ],
    }
  end

  let(:subject) { described_class.new(api_response, referentiel) }

  describe '.format_response' do
    it 'formats the response for autocomplete' do
      result = subject.format_response
      expect(result).to match_array([
        {
          id: Digest::MD5.hexdigest({ 'finess' => 'Tango', 'ej_rs' => 'Charlie' }.to_json),
          label: 'Tango (Charlie)',
          value: 'Tango (Charlie)',
          data: anything,
        },
        {
          id: Digest::MD5.hexdigest({ 'finess' => 'Bob', 'ej_rs' => 'Delta' }.to_json),
          label: 'Bob (Delta)',
          value: 'Bob (Delta)',
          data: anything,
        },
      ])
      expect(result.map { |item| item[:id] }.uniq.count).to eq(2)
    end

    context 'when the template renders an empty label' do
      before do
        referentiel.json_template = { "type" => "doc", "content" => [{ "type" => "paragraph" }] }
      end

      it 'returns no result rather than blank rows' do
        expect(subject.format_response).to be_empty
      end
    end

    context 'with duplicate data' do
      let(:api_response) do
        {
          'items' => [
            { 'finess' => 'Dupli', 'ej_rs' => 'A' },
            { 'finess' => 'Dupli', 'ej_rs' => 'A' },
          ],
        }
      end

      it 'deduplicates by id since data is identical' do
        result = subject.format_response
        expect(result.count).to eq(1)
        expect(result.first[:id]).to eq(Digest::MD5.hexdigest({ 'finess' => 'Dupli', 'ej_rs' => 'A' }.to_json))
        expect(result.first[:value]).to eq('Dupli (A)')
      end
    end
  end

  describe '.render_template' do
    it 'generates plain text from the template and the object' do
      obj = {
        'finess' => 'Tango',
        'ej_rs' => "Charlie",
      }
      expect(
        subject.send(:render_template, referentiel.json_template, obj).join('')
      ).to include('Tango (Charlie)')
    end

    context 'with nodes the renderer does not interpolate' do
      let(:obj) { { 'finess' => 'Tango' } }
      let(:mention) { { "type" => "mention", "attrs" => { "id" => "$.finess", "label" => "$.finess" } } }

      def render(template) = subject.send(:render_template, template, obj).join('')

      it 'skips an empty paragraph, which tiptap serializes without a content key' do
        template = {
          "type" => "doc",
          "content" => [{ "type" => "paragraph" }, { "type" => "paragraph", "content" => [mention] }],
        }
        expect(render(template)).to eq('Tango')
      end

      it 'skips a line break' do
        template = {
          "type" => "doc",
          "content" => [{ "type" => "paragraph", "content" => [mention, { "type" => "hardBreak" }] }],
        }
        expect(render(template)).to eq('Tango')
      end

      it 'renders the children of an unknown node type instead of failing' do
        template = {
          "type" => "doc",
          "content" => [{ "type" => "heading", "attrs" => { "level" => 2 }, "content" => [mention] }],
        }
        expect(render(template)).to eq('Tango')
      end

      it 'skips a mention without a jsonpath' do
        template = { "type" => "doc", "content" => [{ "type" => "mention" }, mention] }
        expect(render(template)).to eq('Tango')
      end

      it 'renders nothing for an empty template' do
        expect(render({})).to eq('')
        expect(render(nil)).to eq('')
      end
    end

    context 'with incompatible keys with passwed to JsonPath' do
      it 'works' do
        obj = {
          "Prénom d'exercice" => "SOPHIE",
        }
        referentiel.json_template = {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
                "content" =>
                [
                  { "type" => "mention", "attrs" => { "id" => "$.Prénom d'exercice", "label" => "$.Prénom d'exercice (SOPHIE)" } },
                  { "text" => "  ", "type" => "text" },
                ],
            },
          ],
        }
        expect(
          subject.send(:render_template, referentiel.json_template, obj).join('')
        ).to include('SOPHIE')
      end
    end
  end
end
