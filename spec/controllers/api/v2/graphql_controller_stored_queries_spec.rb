# frozen_string_literal: true

describe API::V2::GraphqlController do
  let(:admin) { administrateurs.default }
  let(:generated_token) { APIToken.generate(admin) }
  let(:api_token) { generated_token.first }
  let(:token) { generated_token.second }
  let(:procedure) { create(:procedure, :published, :for_individual, :with_service, administrateurs: [admin], types_de_champ_public:) }
  let(:types_de_champ_public) { [] }
  let(:dossier)  { create(:dossier, :en_construction, :with_individual, procedure:, depose_at: 4.days.ago) }
  let(:dossier1) { create(:dossier, :en_construction, :with_individual, procedure:, en_construction_at: 1.day.ago, depose_at: 3.days.ago) }
  let(:dossier2) { create(:dossier, :en_construction, :with_individual, :archived, procedure:, en_construction_at: 3.days.ago, depose_at: 2.days.ago) }
  let(:dossier3) { create(:dossier, :accepte, :with_individual, procedure:, depose_at: 1.day.ago) }
  let(:dossier_accepte) { create(:dossier, :accepte, :with_individual, procedure:) }
  let(:dossier_accepte1) { create(:dossier, :accepte, :with_individual, procedure:) }
  let(:dossier_accepte2) { create(:dossier, :accepte, :with_individual, procedure:) }
  let(:dossiers) { [dossier] }
  let(:instructeur) { create(:instructeur, followed_dossiers: dossiers) }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }

  before do
    instructeur.assign_to_procedure(procedure)
  end

  let(:query_id) { nil }
  let(:variables) { {} }
  let(:operation_name) { nil }
  let(:body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:gql_data) { body[:data] }
  let(:gql_errors) { body[:errors] }

  subject { post :execute, params: { queryId: query_id, variables: variables, operationName: operation_name }.compact, as: :json }

  before do
    request.env['HTTP_AUTHORIZATION'] = authorization_header
  end

  describe 'introspection' do
    let(:query_id) { 'introspection' }
    let(:operation_name) { 'IntrospectionQuery' }
    let(:champ_descriptor) { gql_data[:__schema][:types].find { _1[:name] == 'ChampDescriptor' } }

    it {
      expect(gql_errors).to be_nil
      expect(gql_data[:__schema]).not_to be_nil
      expect(champ_descriptor).not_to be_nil
      expect(champ_descriptor[:fields].find { _1[:name] == 'options' }).to be_nil
    }
  end

  describe 'when not authenticated' do
    let(:variables) { { dossierNumber: dossier.id } }
    let(:operation_name) { 'getDossier' }
    let!(:authorization_header) { nil }

    context 'with query' do
      let(:query) { 'query getDossier($dossierNumber: Int!) { dossier(number: $dossierNumber) { id } }' }

      it { expect(gql_errors.first[:message]).to eq('Without a token, only the public getDemarcheDescriptor query and introspection are allowed') }
    end
  end

  describe 'token authentication' do
    let(:query_id) { 'ds-query-v2' }
    let(:operation_name) { 'getDemarche' }
    let(:variables) { { demarcheNumber: procedure.id } }

    describe 'logging' do
      it "generates correct LogRage payload" do
        @rs = nil
        expect(controller).to receive(:request_logs).and_wrap_original do |m, *args|
          @rs = m.call(*args)
        end
        gql_data
        expect(@rs[:user_id]).to eq(admin.user.id)
        expect(@rs[:user_roles]).to eq("User, Instructeur, Administrateur")
      end
    end

    it {
      expect(gql_errors).to be_nil
      expect(gql_data).not_to be_nil
    }

    context "when the token is invalid" do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials('invalid')
      end

      it {
        expect(gql_errors.first[:message]).to eq("Without a token, only the public getDemarcheDescriptor query and introspection are allowed")
      }
    end

    context "when the token does not belong to an admin of the procedure" do
      let(:another_administrateur) { create(:administrateur) }
      let(:token_v3) { APIToken.generate(another_administrateur)[1] }

      context 'v3' do
        let(:token) { token_v3 }

        it {
          expect(gql_errors.first[:message]).to eq("An object of type Demarche was hidden due to permissions")
        }
      end
    end

    context "when the token is revoked" do
      before do
        admin.api_tokens.destroy_all
      end

      it {
        expect(token).not_to be_nil
        expect(gql_errors.first[:message]).to eq("Without a token, only the public getDemarcheDescriptor query and introspection are allowed")
      }
    end

    context 'when procedure is not selected' do
      let(:other_procedure) { create(:procedure, administrateurs: [admin]) }
      before { api_token.update(allowed_procedure_ids: [other_procedure.id]) }

      it {
        expect(gql_errors.first[:message]).to eq("An object of type Demarche was hidden due to permissions")
      }
    end

    context 'when requires_ip_filtering is true and no networks defined (auto-assign)' do
      before do
        api_token.update!(requires_ip_filtering: true, authorized_networks: [])
        request.remote_ip = '10.20.30.40'
      end

      it 'auto-assigns the IP on first call and succeeds' do
        expect(gql_errors).to be_nil
        expect(api_token.reload.authorized_networks).to eq([IPAddr.new('10.20.30.40')])
      end
    end

    context 'when requires_ip_filtering is false and no networks defined (legacy)' do
      before do
        api_token.update!(requires_ip_filtering: false, authorized_networks: [])
        request.remote_ip = '10.20.30.40'
      end

      it 'does not auto-assign' do
        expect(gql_errors).to be_nil
        expect(api_token.reload.authorized_networks).to be_empty
      end
    end

    context 'when auto-assigned IP blocks subsequent call from different IP' do
      before do
        api_token.update!(requires_ip_filtering: true, authorized_networks: [IPAddr.new('10.20.30.40')])
        request.remote_ip = '192.168.1.1'
      end

      it 'returns forbidden' do
        expect(subject).to have_http_status(:forbidden)
      end
    end
  end

  describe 'ds-query-v2' do
    let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure:, depose_at: 4.days.ago) }
    let(:query_id) { 'ds-query-v2' }

    context 'not found operation id' do
      let(:query_id) { 'ds-query-v0' }

      it {
        expect(subject).to have_http_status(:bad_request)
        expect(gql_errors.first[:message]).to eq('No query with id "ds-query-v0"')
        expect(gql_errors.first[:extensions]).to eq(code: 'bad_request')
      }
    end

    context 'not found operation name' do
      let(:operation_name) { 'getStuff' }

      it {
        expect(gql_errors.first[:message]).to eq('No operation named "getStuff"')
      }
    end

    context 'timeout' do
      let(:variables) { { dossierNumber: dossier.id } }
      let(:operation_name) { 'getDossier' }

      before { allow_any_instance_of(API::V2::Schema::Timeout).to receive(:max_seconds).and_return(0) }

      it {
        expect(gql_errors.first[:message]).to start_with('Timeout on ')
        expect(gql_errors.first[:extensions]).to eq({ code: 'timeout' })
      }
    end

    context 'getDossier' do
      let(:variables) { { dossierNumber: dossier.id } }
      let(:operation_name) { 'getDossier' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossier][:connectionUsager]).to eq('password')
        expect(gql_data[:dossier][:demandeur][:__typename]).to eq('PersonnePhysique')
        expect(gql_data[:dossier][:demandeur][:nom]).to eq(dossier.individual.nom)
        expect(gql_data[:dossier][:demandeur][:prenom]).to eq(dossier.individual.prenom)
        expect(gql_data[:dossier][:labels]).to be_nil
      }

      context 'include Labels' do
        let(:variables) { { dossierNumber: dossier.id, includeLabels: true } }
        let(:label) { create(:label, procedure:) }

        before { dossier.labels << label }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:dossier][:labels]).to eq([{ id: label.to_typed_id, name: label.name, color: label.color }])
        }
      end

      context 'not found' do
        let(:variables) { { dossierNumber: 0 } }

        it {
          expect(gql_errors.first[:message]).to eq('Dossier not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
        }
      end

      context 'with entreprise' do
        let(:procedure) { procedures.entreprise }
        # the local `let(:dossiers)` shadows the seed accessor, so go through Oaken::Seeds
        let(:dossier) { Oaken::Seeds.dossiers.avec_siret }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
          expect(gql_data[:dossier][:demandeur][:__typename]).to eq('PersonneMorale')
          expect(gql_data[:dossier][:demandeur][:siret]).to eq(dossier.etablissement.siret)
          expect(gql_data[:dossier][:demandeur][:libelleNaf]).to eq(dossier.etablissement.libelle_naf)
        }

        context 'when in degraded mode' do
          before { dossier.etablissement.update(adresse: nil) }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
            expect(gql_data[:dossier][:demandeur][:__typename]).to eq('PersonneMoraleIncomplete')
            expect(gql_data[:dossier][:demandeur][:siret]).to eq(dossier.etablissement.siret)
            expect(gql_data[:dossier][:demandeur][:libelleNaf]).to be_nil
          }
        end

        context 'when there are missing data' do
          before do
            dossier.etablissement.update!(entreprise_code_effectif_entreprise: nil, entreprise_capital_social: nil, entreprise_numero_tva_intracommunautaire: nil)
          end

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:dossier][:demandeur][:__typename]).to eq('PersonneMorale')
            expect(gql_data[:dossier][:demandeur][:entreprise]).to include(
              siren: dossier.etablissement.entreprise_siren,
              dateCreation: dossier.etablissement.entreprise_date_creation.iso8601,
              capitalSocial: '-1',
              codeEffectifEntreprise: nil,
              numeroTvaIntracommunautaire: nil
            )
          }
        end
      end

      context 'columns' do
        let(:types_de_champ_public) do
          [
            { libelle: 'label text' },
            { type: :integer_number, libelle: 'label integer_number' },
            { type: :decimal_number, libelle: 'label decimal_number' },
            { type: :checkbox, libelle: 'label checkbox' },
            { type: :piece_justificative, libelle: 'label piece_justificative' },
            { type: :multiple_drop_down_list, libelle: 'label multiple_drop_down_list' },
            { type: :siret, libelle: 'label entreprise' },
          ]
        end
        let(:dossier) { create(:dossier, :en_construction, :with_individual, :with_populated_champs, procedure:) }
        let(:columns) { gql_data[:dossier][:champs].flat_map { _1[:columns] } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
          expect(gql_data[:dossier][:champs].size).to eq(7)
          expect(columns.size).to eq(19)

          expect(columns[0]).to include(label: "label text", value: 'text')
          expect(columns[1]).to include(label: "label integer_number", value: "42")
          expect(columns[2]).to include(label: "label decimal_number", value: 42.1)
          expect(columns[3]).to include(label: "label checkbox", value: true)
          expect(columns[4][:value].first).to include(__typename: "File", filename: "toto.txt", contentType: "text/plain")
          expect(columns[5]).to include(label: "label multiple_drop_down_list", value: ["val1", "val2"])

          expect(columns[6]).to include(label: "label entreprise – SIRET", value: '44011762001530')
          expect(columns[7]).to include(label: "label entreprise – Entreprise raison sociale", value: 'GRTGAZ')
          expect(columns[16]).to include(label: "label entreprise – SIRET – Département", value: '92')
          expect(columns[17]).to include(label: "label entreprise – SIRET – Région", value: '11')
          expect(columns[18]).to include(label: "label entreprise – SIRET – Région", value: 'Île-de-France')
        }
      end
    end

    context 'getDemarche' do
      let(:variables) { { demarcheNumber: procedure.id } }
      let(:operation_name) { 'getDemarche' }

      before { dossier }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
        expect(gql_data[:demarche][:description]).to eq(procedure.description)
        expect(gql_data[:demarche][:dateDerniereModification]).to eq(procedure.updated_at.iso8601)
        expect(gql_data[:demarche][:dossiers]).to be_nil
        expect(gql_data[:demarche][:labels]).to be_nil
      }

      context 'include Labels' do
        let(:variables) { { demarcheNumber: procedure.id, includeLabels: true } }
        let!(:label) { create(:label, procedure:) }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:labels]).to eq([{ id: label.to_typed_id, name: label.name, color: label.color }])
        }
      end

      context 'not found' do
        let(:variables) { { demarcheNumber: 0 } }

        it {
          expect(gql_errors.first[:message]).to eq('Demarche not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
        }
      end

      context 'with an out of bounds number' do
        let(:variables) { { demarcheNumber: 10_000_000_000_000_000 } }

        it "returns a validation error instead of an internal error" do
          expect(Sentry).not_to receive(:capture_exception)
          expect(subject).to have_http_status(:ok)
          expect(gql_errors.first[:message]).to match(/invalid value|out of bounds/)
        end
      end

      context 'include Revision' do
        let(:variables) { { demarcheNumber: procedure.id, includeRevision: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarche][:activeRevision]).not_to be_nil
        }
      end

      context 'include Dossiers' do
        def cursor_for(item, column)
          cursor = [item.reload.read_attribute(column).utc.strftime("%Y-%m-%dT%H:%M:%S.%NZ"), item.id].join(';')
          API::V2::Schema.cursor_encoder.encode(cursor, nonce: true)
        end

        let(:order_column) { :depose_at }
        let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true } }
        let(:start_cursor) { cursor_for(dossier, order_column) }
        let(:end_cursor) { cursor_for(dossier3, order_column) }

        before { dossier1; dossier2; dossier3 }

        context 'createdSince' do
          let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, createdSince: 2.5.days.ago.iso8601 } }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarche][:dossiers][:nodes].map { _1[:id] }).to eq([dossier2, dossier3].map(&:to_typed_id))
          }
        end

        context 'archived' do
          let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, archived: true } }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarche][:dossiers][:nodes].map { _1[:id] }).to eq([dossier2.to_typed_id])
          }

          context 'false' do
            let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, archived: false } }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:dossiers][:nodes].map { _1[:id] }).to eq([dossier, dossier1, dossier3].map(&:to_typed_id))
            }
          end
        end

        context 'depose_at' do
          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
            expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(4)
            expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
            expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
            expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
            expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
          }

          context 'first' do
            let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2 } }
            let(:end_cursor) { cursor_for(dossier1, order_column) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
              expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }

            context 'with deprecated order' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, order: 'DESC' } }
              let(:start_cursor) { cursor_for(dossier3, order_column) }
              let(:end_cursor) { cursor_for(dossier2, order_column) }

              it {
                allow(Rails.logger).to receive(:info)
                expect(Rails.logger).to receive(:info).with("{\"message\":\"CursorConnection: using deprecated order [#{admin.email}]\",\"user_id\":#{admin.user.id}}")

                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }

              context 'after' do
                let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, after: current_cursor, order: 'DESC' } }
                let(:current_cursor) { cursor_for(dossier2, order_column) }
                let(:start_cursor) { cursor_for(dossier1, order_column) }
                let(:end_cursor) { cursor_for(dossier, order_column) }

                it {
                  allow(Rails.logger).to receive(:info)
                  expect(Rails.logger).to receive(:info).with("{\"message\":\"CursorConnection: using deprecated order [#{admin.email}]\",\"user_id\":#{admin.user.id}}")

                  expect(gql_errors).to be_nil
                  expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
                }
              end

              context 'before' do
                let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, before: current_cursor, order: 'DESC' } }
                let(:current_cursor) { cursor_for(dossier1, order_column) }
                let(:start_cursor) { cursor_for(dossier3, order_column) }
                let(:end_cursor) { cursor_for(dossier2, order_column) }

                it {
                  allow(Rails.logger).to receive(:info)
                  expect(Rails.logger).to receive(:info).with("{\"message\":\"CursorConnection: using deprecated order [#{admin.email}]\",\"user_id\":#{admin.user.id}}")

                  expect(gql_errors).to be_nil
                  expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                  expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
                }
              end
            end

            context 'after' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, after: current_cursor } }
              let(:current_cursor) { cursor_for(dossier1, order_column) }
              let(:start_cursor) { cursor_for(dossier2, order_column) }
              let(:end_cursor) { cursor_for(dossier3, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }

              context 'with deleted' do
                let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true } }

                before { dossier.hide_and_keep_track!(dossier.user, DeletedDossier.reasons.fetch(:user_request)) }

                it {
                  expect(gql_errors).to be_nil
                  expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(3)
                }

                context 'second page not changed' do
                  let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, after: current_cursor } }

                  it {
                    expect(gql_errors).to be_nil
                    expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                    expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
                    expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
                    expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                    expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
                  }
                end
              end
            end

            context 'before' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, before: current_cursor } }
              let(:current_cursor) { cursor_for(dossier2, order_column) }
              let(:start_cursor) { cursor_for(dossier, order_column) }
              let(:end_cursor) { cursor_for(dossier1, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }
            end
          end

          context 'last' do
            let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, last: 2 } }
            let(:start_cursor) { cursor_for(dossier2, order_column) }
            let(:end_cursor) { cursor_for(dossier3, order_column) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
              expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }

            context 'before' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, last: 2, before: current_cursor } }
              let(:current_cursor) { cursor_for(dossier2, order_column) }
              let(:start_cursor) { cursor_for(dossier, order_column) }
              let(:end_cursor) { cursor_for(dossier1, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }
            end

            context 'after' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, last: 2, after: current_cursor } }
              let(:current_cursor) { cursor_for(dossier1, order_column) }
              let(:start_cursor) { cursor_for(dossier2, order_column) }
              let(:end_cursor) { cursor_for(dossier3, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }
            end
          end
        end

        context 'updated_at' do
          let(:order_column) { :updated_at }

          context 'first' do
            let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, updatedSince: 10.days.ago.iso8601 } }
            let(:end_cursor) { cursor_for(dossier1, order_column) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
              expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }

            context 'after' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, after: current_cursor, updatedSince: 10.days.ago.iso8601 } }
              let(:current_cursor) { cursor_for(dossier1, order_column) }
              let(:start_cursor) { cursor_for(dossier2, order_column) }
              let(:end_cursor) { cursor_for(dossier3, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }
            end

            context 'before' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, first: 2, before: current_cursor, updatedSince: 10.days.ago.iso8601 } }
              let(:current_cursor) { cursor_for(dossier2, order_column) }
              let(:start_cursor) { cursor_for(dossier, order_column) }
              let(:end_cursor) { cursor_for(dossier1, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }
            end
          end

          context 'last' do
            let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, last: 2, updatedSince: 10.days.ago.iso8601 } }
            let(:start_cursor) { cursor_for(dossier2, order_column) }
            let(:end_cursor) { cursor_for(dossier3, order_column) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
              expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
              expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }

            context 'before' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, last: 2, before: current_cursor, updatedSince: 10.days.ago.iso8601 } }
              let(:current_cursor) { cursor_for(dossier2, order_column) }
              let(:start_cursor) { cursor_for(dossier, order_column) }
              let(:end_cursor) { cursor_for(dossier1, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }
            end

            context 'after' do
              let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, last: 2, after: current_cursor, updatedSince: 10.days.ago.iso8601 } }
              let(:current_cursor) { cursor_for(dossier1, order_column) }
              let(:start_cursor) { cursor_for(dossier2, order_column) }
              let(:end_cursor) { cursor_for(dossier3, order_column) }

              it {
                expect(gql_errors).to be_nil
                expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(2)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasNextPage]).to be_falsey
                expect(gql_data[:demarche][:dossiers][:pageInfo][:hasPreviousPage]).to be_truthy
                expect(gql_data[:demarche][:dossiers][:pageInfo][:startCursor]).to eq(start_cursor)
                expect(gql_data[:demarche][:dossiers][:pageInfo][:endCursor]).to eq(end_cursor)
              }
            end
          end
        end
      end

      context 'include deleted Dossiers' do
        def cursor_for(item)
          cursor = [item.reload.deleted_at.utc.strftime("%Y-%m-%dT%H:%M:%S.%NZ"), item.id].join(';')
          API::V2::Schema.cursor_encoder.encode(cursor, nonce: true)
        end

        let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedSince: 2.weeks.ago.iso8601 } }
        let(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier_accepte, DeletedDossier.reasons.fetch(:user_request)).tap { _1.update(deleted_at: 4.days.ago) } }
        let(:deleted_dossier1) { DeletedDossier.create_from_dossier(dossier_accepte1, DeletedDossier.reasons.fetch(:user_request)).tap { _1.update(deleted_at: 3.days.ago) } }
        let(:deleted_dossier2) { DeletedDossier.create_from_dossier(dossier_accepte2, DeletedDossier.reasons.fetch(:user_request)).tap { _1.update(deleted_at: 2.days.ago) } }
        let(:deleted_dossier3) { DeletedDossier.create_from_dossier(dossier3, DeletedDossier.reasons.fetch(:user_request)).tap { _1.update(deleted_at: 1.day.ago) } }

        let(:start_cursor) { cursor_for(deleted_dossier) }
        let(:end_cursor) { cursor_for(deleted_dossier3) }

        before { deleted_dossier; deleted_dossier1; deleted_dossier2; deleted_dossier3 }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(4)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].first[:id]).to eq(deleted_dossier.to_typed_id)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].first[:number]).to eq(deleted_dossier.dossier_id)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].first[:state]).to eq(deleted_dossier.state)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].first[:reason]).to eq(deleted_dossier.reason)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].first[:dateSupression]).to eq(deleted_dossier.deleted_at.iso8601)
        }

        context 'first' do
          let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedFirst: 2 } }
          let(:end_cursor) { cursor_for(deleted_dossier1) }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(2)
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasNextPage]).to be_truthy
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasPreviousPage]).to be_falsey
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
          }

          context 'after' do
            let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedFirst: 2, deletedAfter: current_cursor } }
            let(:current_cursor) { cursor_for(deleted_dossier1) }
            let(:start_cursor) { cursor_for(deleted_dossier2) }
            let(:end_cursor) { cursor_for(deleted_dossier3) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasNextPage]).to be_falsey
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasPreviousPage]).to be_truthy
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end

          context 'before' do
            let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedFirst: 2, deletedBefore: current_cursor } }
            let(:current_cursor) { cursor_for(deleted_dossier2) }
            let(:start_cursor) { cursor_for(deleted_dossier) }
            let(:end_cursor) { cursor_for(deleted_dossier1) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasNextPage]).to be_truthy
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasPreviousPage]).to be_falsey
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end
        end

        context 'last' do
          let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedLast: 2 } }
          let(:start_cursor) { cursor_for(deleted_dossier2) }
          let(:end_cursor) { cursor_for(deleted_dossier3) }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(2)
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasNextPage]).to be_falsey
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasPreviousPage]).to be_truthy
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
            expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
          }

          context 'before' do
            let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedLast: 2, deletedBefore: current_cursor } }
            let(:current_cursor) { cursor_for(deleted_dossier2) }
            let(:start_cursor) { cursor_for(deleted_dossier) }
            let(:end_cursor) { cursor_for(deleted_dossier1) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasNextPage]).to be_truthy
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasPreviousPage]).to be_falsey
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end

          context 'after' do
            let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedLast: 2, deletedAfter: current_cursor } }
            let(:current_cursor) { cursor_for(deleted_dossier1) }
            let(:start_cursor) { cursor_for(deleted_dossier2) }
            let(:end_cursor) { cursor_for(deleted_dossier3) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasNextPage]).to be_falsey
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:hasPreviousPage]).to be_truthy
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:deletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end
        end
      end

      context 'include pending deleted Dossiers' do
        def cursor_for(item)
          cursor = [(item.reload.en_construction? ? item.hidden_by_user_at : item.hidden_by_administration_at).utc.strftime("%Y-%m-%dT%H:%M:%S.%NZ"), item.id].join(';')
          API::V2::Schema.cursor_encoder.encode(cursor, nonce: true)
        end

        let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedSince: 2.weeks.ago.iso8601 } }

        let(:pending_deleted_dossier) do
          dossier.hide_and_keep_track!(dossier.user, DeletedDossier.reasons.fetch(:user_request))
          dossier.tap { _1.update(hidden_by_user_at: 4.days.ago) }
        end
        let(:pending_deleted_dossier1) do
          dossier_accepte.hide_and_keep_track!(instructeur, DeletedDossier.reasons.fetch(:instructeur_request))
          dossier_accepte.tap { _1.update(hidden_by_administration_at: 3.days.ago) }
        end
        let(:pending_deleted_dossier2) do
          dossier1.hide_and_keep_track!(dossier.user, DeletedDossier.reasons.fetch(:user_request))
          dossier1.tap { _1.update(hidden_by_user_at: 2.days.ago) }
        end
        let(:pending_deleted_dossier3) do
          dossier_accepte1.hide_and_keep_track!(instructeur, DeletedDossier.reasons.fetch(:instructeur_request))
          dossier_accepte1.tap { _1.update(hidden_by_administration_at: 1.day.ago) }
        end

        let(:start_cursor) { cursor_for(pending_deleted_dossier) }
        let(:end_cursor) { cursor_for(pending_deleted_dossier3) }

        before { pending_deleted_dossier; pending_deleted_dossier1; pending_deleted_dossier2; pending_deleted_dossier3 }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(4)
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].first[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier.id))
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].second[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier_accepte.id))
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].first[:dateSupression]).to eq(pending_deleted_dossier.hidden_by_user_at.iso8601)
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].second[:dateSupression]).to eq(pending_deleted_dossier1.hidden_by_administration_at.iso8601)
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].first[:dateSupression] < gql_data[:demarche][:pendingDeletedDossiers][:nodes].second[:dateSupression]).to be_truthy
        }

        context 'first' do
          let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedFirst: 2 } }
          let(:end_cursor) { cursor_for(pending_deleted_dossier1) }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(2)
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasNextPage]).to be_truthy
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasPreviousPage]).to be_falsey
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
          }

          context 'after' do
            let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedFirst: 2, pendingDeletedAfter: current_cursor } }
            let(:current_cursor) { cursor_for(pending_deleted_dossier1) }
            let(:start_cursor) { cursor_for(pending_deleted_dossier2) }
            let(:end_cursor) { cursor_for(pending_deleted_dossier3) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasNextPage]).to be_falsey
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasPreviousPage]).to be_truthy
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end

          context 'before' do
            let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedFirst: 2, pendingDeletedBefore: current_cursor } }
            let(:current_cursor) { cursor_for(pending_deleted_dossier2) }
            let(:start_cursor) { cursor_for(pending_deleted_dossier) }
            let(:end_cursor) { cursor_for(pending_deleted_dossier1) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasNextPage]).to be_truthy
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasPreviousPage]).to be_falsey
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end
        end

        context 'last' do
          let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedLast: 2 } }
          let(:start_cursor) { cursor_for(pending_deleted_dossier2) }
          let(:end_cursor) { cursor_for(pending_deleted_dossier3) }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(2)
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasNextPage]).to be_falsey
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasPreviousPage]).to be_truthy
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
            expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
          }

          context 'before' do
            let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedLast: 2, pendingDeletedBefore: current_cursor } }
            let(:current_cursor) { cursor_for(pending_deleted_dossier2) }
            let(:start_cursor) { cursor_for(pending_deleted_dossier) }
            let(:end_cursor) { cursor_for(pending_deleted_dossier1) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasNextPage]).to be_truthy
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasPreviousPage]).to be_falsey
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end

          context 'after' do
            let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedLast: 2, pendingDeletedAfter: current_cursor } }
            let(:current_cursor) { cursor_for(pending_deleted_dossier1) }
            let(:start_cursor) { cursor_for(pending_deleted_dossier2) }
            let(:end_cursor) { cursor_for(pending_deleted_dossier3) }

            it {
              expect(gql_errors).to be_nil
              expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(2)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasNextPage]).to be_falsey
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:hasPreviousPage]).to be_truthy
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:startCursor]).to eq(start_cursor)
              expect(gql_data[:demarche][:pendingDeletedDossiers][:pageInfo][:endCursor]).to eq(end_cursor)
            }
          end
        end
      end
    end

    context 'getGroupeInstructeur' do
      let(:groupe_instructeur) { procedure.groupe_instructeurs.first }
      let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id } }
      let(:operation_name) { 'getGroupeInstructeur' }

      before { dossier }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
        expect(gql_data[:groupeInstructeur][:number]).to eq(groupe_instructeur.id)
        expect(gql_data[:groupeInstructeur][:label]).to eq(groupe_instructeur.label)
        expect(gql_data[:groupeInstructeur][:dossiers]).to be_nil
      }

      context 'not found' do
        let(:variables) { { groupeInstructeurNumber: 0 } }

        it {
          expect(gql_errors.first[:message]).to eq('GroupeInstructeurWithDossiers not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
        }
      end

      context 'include Dossiers' do
        let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id, includeDossiers: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
          expect(gql_data[:groupeInstructeur][:dossiers][:nodes].size).to eq(1)
        }
      end

      context 'include deleted Dossiers' do
        let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id, includeDeletedDossiers: true, deletedSince: 2.weeks.ago.iso8601 } }
        let(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier_accepte, DeletedDossier.reasons.fetch(:user_request)) }

        before { deleted_dossier }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
          expect(gql_data[:groupeInstructeur][:deletedDossiers][:nodes].size).to eq(1)
          expect(gql_data[:groupeInstructeur][:deletedDossiers][:nodes].first[:id]).to eq(deleted_dossier.to_typed_id)
          expect(gql_data[:groupeInstructeur][:deletedDossiers][:nodes].first[:dateSupression]).to eq(deleted_dossier.deleted_at.iso8601)
        }
      end

      context 'include pending deleted Dossiers' do
        let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id, includePendingDeletedDossiers: true, pendingDeletedSince: 2.weeks.ago.iso8601 } }

        before {
          dossier.hide_and_keep_track!(dossier.user, DeletedDossier.reasons.fetch(:user_request))
          travel_to(3.hours.ago) {
            dossier_accepte.hide_and_keep_track!(instructeur, DeletedDossier.reasons.fetch(:instructeur_request))
          }
        }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].size).to eq(2)
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].first[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier_accepte.id))
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].second[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier.id))
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].first[:dateSupression]).to eq(dossier_accepte.hidden_by_administration_at.iso8601)
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].second[:dateSupression]).to eq(dossier.hidden_by_user_at.iso8601)
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].first[:dateSupression] < gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].second[:dateSupression])
        }
      end
    end

    context 'getDemarcheDescriptor' do
      let(:operation_name) { 'getDemarcheDescriptor' }
      let(:types_de_champ_public) { [{ type: :text }, { type: :piece_justificative }, { type: :regions }] }

      context 'find by number' do
        let(:variables) { { demarche: { number: procedure.id }, includeRevision: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarcheDescriptor][:demarcheURL]).to match("commencer/#{procedure.path}")
        }
      end

      context 'not found' do
        let(:variables) { { demarche: { number: 0 } } }

        it {
          expect(gql_errors.first[:message]).to eq('DemarcheDescriptor not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
        }
      end

      context 'find by id' do
        let(:variables) { { demarche: { id: procedure.to_typed_id } } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
        }
      end

      context 'not opendata' do
        let(:variables) { { demarche: { id: procedure.to_typed_id } } }

        before { procedure.update(opendata: false) }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
        }
      end

      context 'without authorization token' do
        let(:authorization_header) { nil }

        context 'opendata' do
          let(:variables) { { demarche: { id: procedure.to_typed_id } } }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
          }
        end

        context 'not opendata' do
          let(:variables) { { demarche: { id: procedure.to_typed_id } } }

          before { procedure.update(opendata: false) }

          it {
            expect(gql_errors).not_to be_nil
            expect(gql_errors.first[:message]).to eq('An object of type DemarcheDescriptor was hidden due to permissions')
          }
        end
      end
    end
  end
end
