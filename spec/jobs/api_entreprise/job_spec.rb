# frozen_string_literal: true

include ActiveJob::TestHelper

RSpec.describe APIEntreprise::Job, type: :job do
  describe '#perform' do
    let(:dossier) { create(:dossier, :with_entreprise) }

    context 'when error with an etablissement on a champ' do
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:types_de_champ_public) { [{ type: :siret }] }
      let(:dossier) { create(:dossier, procedure:) }

      it "re-raises so sidekiq can retry" do
        champ = dossier.champs.first
        champ.update!(value: '12345678901234')

        etablissement = create(:etablissement, champ:)

        expect { ErrorJob.perform_now(:service_unavailable, etablissement) }
          .to raise_error(APIEntreprise::API::Error::ServiceUnavailable)

        expect(champ.reload.value).not_to be_nil
      end
    end
  end

  class ErrorJob < APIEntreprise::Job
    def perform(error, etablissement)
      @etablissement = etablissement

      response = Typhoeus::Response.new(
        effective_url: 'http://host.com/path',
        code: '666',
        body: 'body',
        return_message: 'return_message',
        total_time: 10,
        connect_time: 20,
        headers: 'headers'
      )

      case error
      when :service_unavailable
        raise APIEntreprise::API::Error::ServiceUnavailable.new(response)
      when :bad_gateway
        raise APIEntreprise::API::Error::BadGateway.new(response)
      when :timed_out
        raise APIEntreprise::API::Error::TimedOut.new(response)
      when :internal_server_error
        raise APIEntreprise::API::Error::InternalServerError.new(response)
      else
        raise StandardError
      end
    end
  end
end
