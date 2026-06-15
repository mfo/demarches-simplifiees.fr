# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260615StripUnderlineMarksFromTiptapBodiesTask do
    def body_with_marks(marks)
      {
        "type" => "doc",
        "content" => [
          {
            "type" => "title",
            "content" => [{ "type" => "text", "text" => "Titre", "marks" => marks }],
          },
        ],
      }
    end

    describe "#process" do
      it "removes the underline mark while keeping other marks" do
        attestation = create(:attestation_template, :v2,
          json_body: body_with_marks([{ "type" => "bold" }, { "type" => "underline" }, { "type" => "italic" }]))

        described_class.process(attestation)

        text_node = attestation.reload.json_body.dig("content", 0, "content", 0)
        expect(text_node["marks"]).to eq([{ "type" => "bold" }, { "type" => "italic" }])
      end

      it "drops the marks key entirely when underline was the only mark" do
        attestation = create(:attestation_template, :v2,
          json_body: body_with_marks([{ "type" => "underline" }]))

        described_class.process(attestation)

        text_node = attestation.reload.json_body.dig("content", 0, "content", 0)
        expect(text_node).not_to have_key("marks")
      end

      it "also cleans dossier submitted messages" do
        message = create(:dossier_submitted_message,
          json_body: body_with_marks([{ "type" => "underline" }]))

        described_class.process(message)

        text_node = message.reload.json_body.dig("content", 0, "content", 0)
        expect(text_node).not_to have_key("marks")
      end
    end

    describe "#collection" do
      it "only includes records whose json_body contains an underline mark" do
        with_underline = create(:attestation_template, :v2,
          json_body: body_with_marks([{ "type" => "underline" }]))
        without_underline = create(:attestation_template, :v2,
          json_body: body_with_marks([{ "type" => "italic" }]))

        collection = described_class.collection

        expect(collection).to include(with_underline)
        expect(collection).not_to include(without_underline)
      end
    end
  end
end
