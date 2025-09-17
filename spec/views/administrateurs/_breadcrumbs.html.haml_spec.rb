# frozen_string_literal: true

require 'rails_helper'

describe 'administrateurs/breadcrumbs', type: :view do
  let(:procedure) do
    instance_double(Procedure,
                    libelle: 'Ma démarche',
                    close?: false,
                    locked?: true,
                    path: 'ma-demarche',
                    id: 42,
                    published_at: Time.zone.local(2024, 1, 15),
                    closed_at: nil,
                    created_at: Time.zone.local(2023, 5, 10),
                    api_entreprise_token: double('ApiEntrepriseToken', expired_or_expires_soon?: false))
  end
  let(:steps) { [['Accueil', '/'], ['Démarches', '/procedures'], ['Paramètres', '#']] }

  before do
    allow(procedure).to receive(:to_param).and_return(procedure.id.to_s)
    assign(:procedure, procedure)
  end

  it 'renders the breadcrumb trail with metadatas' do
    render partial: 'administrateurs/breadcrumbs', locals: { steps: steps, metadatas: true }

    expect(rendered).to include('breadcrumbs')
    expect(rendered).to include(procedure.libelle)
  end
end
