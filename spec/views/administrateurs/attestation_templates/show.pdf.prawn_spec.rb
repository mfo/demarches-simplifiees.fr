# frozen_string_literal: true

describe 'administrateurs/attestation_templates/show.pdf', :external_deps, type: :view do
  PDFTOTEXT_AVAILABLE = system('which pdftotext > /dev/null 2>&1') unless defined?(PDFTOTEXT_AVAILABLE)

  let(:attestation) do
    {
      title: "Titre\u00A0: <b>gras</b>",
      body: "Prix\u00A0: 12\u00A0€ & <n° dossier> pour les <18 ans",
      footer: "Pied\u00A0de\u00A0page",
      created_at: Time.zone.local(2026, 9, 9),
      logo: nil,
      signature: nil,
    }
  end

  def render_and_extract
    assign(:attestation, attestation)
    render template: 'administrateurs/attestation_templates/show', formats: [:pdf]

    pdf_path = Rails.root.join('tmp/test_attestation_v1.pdf')
    File.binwrite(pdf_path, rendered)
    `pdftotext -layout #{pdf_path} - 2>/dev/null`
  end

  it 'renders a PDF' do
    render_and_extract
    expect(rendered).to start_with('%PDF')
  end

  it 'prints non-breaking spaces and ampersands as themselves, and drops hand-typed tags', if: PDFTOTEXT_AVAILABLE do
    text = render_and_extract

    expect(text).to include("Titre : gras")
    expect(text).to match(/Prix : 12 € & +pour les <18 ans/)
    expect(text).to include("Pied de page")
    expect(text).not_to include('&nbsp;')
    expect(text).not_to include('&amp;')
  end
end
