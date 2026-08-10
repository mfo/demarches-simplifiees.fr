# frozen_string_literal: true

RSpec.describe Types::File, type: :graphql do
  let(:query) do
    <<~GRAPHQL
      query($number: Int!) {
        dossier(number: $number) {
          champs {
            ... on PieceJustificativeChamp {
              files {
                byteSize
                byteSizeBigInt
              }
            }
          }
        }
      }
    GRAPHQL
  end
  let(:context) { { internal_use: true } }
  let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :piece_justificative }]) }
  let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:) }
  let(:variables) { { number: dossier.id } }

  subject { API::V2::Schema.execute(query, variables: variables, context: context) }

  let(:data) { subject['data'].deep_symbolize_keys }
  let(:file) { data[:dossier][:champs].first[:files].first }

  describe 'byteSize' do
    it 'returns the blob byte size' do
      expect(subject['errors']).to be_nil
      expect(file[:byteSize]).to eq(file[:byteSizeBigInt].to_i)
    end

    context 'when the file is larger than a 32-bit integer (RAILS-JZ7)' do
      before do
        dossier.champs.first.piece_justificative_file.first.blob.update_column(:byte_size, 3_000_000_000)
      end

      it 'clamps instead of failing the query' do
        expect(subject['errors']).to be_nil
        expect(file[:byteSize]).to eq(GraphQL::Types::Int::MAX)
        expect(file[:byteSizeBigInt]).to eq('3000000000')
      end
    end
  end
end
