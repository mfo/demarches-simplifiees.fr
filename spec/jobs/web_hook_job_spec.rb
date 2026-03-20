# frozen_string_literal: true

describe WebHookJob, type: :job do
  describe 'perform' do
    let(:procedure) { create(:procedure, web_hook_url:) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:web_hook_url) { "https://domaine.fr/callback_url" }
    let(:job) { WebHookJob.new(procedure.id, dossier.id, dossier.state, dossier.updated_at) }

    context 'with success on webhook' do
      it 'calls webhook' do
        stub_request(:post, web_hook_url).to_return(status: 200, body: "success")
        expect { job.perform_now }.not_to raise_error
      end
    end

    context 'with error on webhook' do
      it 'raises' do
        allow(Sentry).to receive(:capture_message)
        stub_request(:post, web_hook_url).to_return(status: 500, body: "error")

        job.perform_now
        expect(Sentry).to have_received(:capture_message)
      end
    end

    context 'SSRF protection' do
      context 'when webhook URL resolves to a private IP' do
        let(:web_hook_url) { "https://domaine.fr/callback_url" }

        it 'does not make the HTTP request when DNS resolves to a private IP' do
          stub = stub_request(:post, web_hook_url).to_return(status: 200, body: "success")
          allow(Resolv).to receive(:getaddresses).with('domaine.fr').and_return(['10.0.0.1'])

          job.perform_now
          expect(stub).not_to have_been_requested
        end

        it 'does not make the HTTP request when DNS resolves to localhost' do
          stub = stub_request(:post, web_hook_url).to_return(status: 200, body: "success")
          allow(Resolv).to receive(:getaddresses).with('domaine.fr').and_return(['127.0.0.1'])

          job.perform_now
          expect(stub).not_to have_been_requested
        end

        it 'does not make the HTTP request when DNS resolves to link-local' do
          stub = stub_request(:post, web_hook_url).to_return(status: 200, body: "success")
          allow(Resolv).to receive(:getaddresses).with('domaine.fr').and_return(['169.254.169.254'])

          job.perform_now
          expect(stub).not_to have_been_requested
        end
      end

      context 'when webhook URL resolves to a public IP' do
        let(:web_hook_url) { "https://domaine.fr/callback_url" }

        it 'makes the HTTP request normally' do
          stub = stub_request(:post, web_hook_url).to_return(status: 200, body: "success")
          allow(Resolv).to receive(:getaddresses).with('domaine.fr').and_return(['93.184.216.34'])

          job.perform_now
          expect(stub).to have_been_requested
        end
      end
    end
  end
end
