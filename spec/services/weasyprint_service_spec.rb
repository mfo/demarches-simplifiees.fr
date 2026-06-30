# frozen_string_literal: true

describe WeasyprintService do
  let(:html) { '<html><body>Hello, World!</body></html>' }
  let(:options) { { procedure_id: 1, dossier_id: 2 } }
  let(:expected_context) { { pdf_variant: 'pdf/ua-1', **options } }

  describe '#generate_pdf' do
    context 'when the Weasyprint API responds successfully' do
      before do
        stub_request(:post, WEASYPRINT_URL)
          .with(body: { html:, upstream_context: expected_context })
          .to_return(body: 'PDF_DATA')
      end

      it 'returns the PDF data' do
        pdf = described_class.generate_pdf(html, options)
        expect(pdf).to eq('PDF_DATA')
      end

      it 'requests the PDF/UA variant by default' do
        described_class.generate_pdf(html, options)
        expect(
          a_request(:post, WEASYPRINT_URL).with(body: { html:, upstream_context: expected_context })
        ).to have_been_made
      end
    end

    context 'when the Weasyprint service is down' do
      before do
        stub_request(:post, WEASYPRINT_URL).to_timeout
      end

      it 'raises WeasyprintService::Error' do
        expect { described_class.generate_pdf(html, options) }
          .to raise_error(WeasyprintService::Error)
      end
    end
  end
end
