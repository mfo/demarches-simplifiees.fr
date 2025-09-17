# frozen_string_literal: true

describe 'administrateurs/_breadcrumbs', type: :view do
  let(:steps) { [["Accueil", '/'], ["Configuration", '/configuration']] }

  before do
    allow(view).to receive(:root_path).and_return('/root')
  end

  def render_partial(locals = {})
    render partial: 'administrateurs/breadcrumbs', locals: { steps: steps }.merge(locals)
    rendered
  end

  context 'without metadata' do
    before do
      assign(:procedure, double('Procedure'))
    end

    it 'renders the breadcrumb trail' do
      html = render_partial

      expect(html).to include('Configuration')
      expect(html).to include('/root')
    end
  end

  context 'with metadata for a closed procedure' do
    let(:closed_at) { Time.zone.parse('2024-02-01') }
    let(:procedure) do
      instance_double('Procedure',
                      libelle: 'Procédure fermée',
                      close?: true,
                      closed_at: closed_at,
                      locked?: false,
                      path: 'fermee',
                      api_entreprise_token: instance_double('Token', expired_or_expires_soon?: false),
                      published_at: Time.zone.parse('2023-05-01'),
                      created_at: Time.zone.parse('2022-04-01'),
                      id: 42)
    end

    before do
      assign(:procedure, procedure)
    end

    it 'displays the closure badge' do
      html = render_partial(metadatas: true)

      expect(html).to include('Procédure fermée')
      expect(html).to include('fr-badge--warning')
      expect(html).to include(I18n.l(closed_at.to_date))
    end
  end

  context 'with metadata for a published procedure' do
    let(:procedure) do
      instance_double('Procedure',
                      libelle: 'Procédure publiée',
                      close?: false,
                      closed_at: nil,
                      locked?: true,
                      path: 'publiee',
                      api_entreprise_token: instance_double('Token', expired_or_expires_soon?: true),
                      published_at: Time.zone.parse('2023-06-15'),
                      created_at: Time.zone.parse('2023-01-10'),
                      id: 87)
    end
    let(:public_link) { 'https://www.example.com/demarche' }
    let(:edit_path_link) { 'https://www.example.com/admin/procedure/path' }

    before do
      assign(:procedure, procedure)
      allow(view).to receive(:commencer_url).with(procedure.path).and_return(public_link)
      allow(view).to receive(:admin_procedure_path_path).with(procedure).and_return(edit_path_link)
    end

    it 'displays the published procedure metadata' do
      html = render_partial(metadatas: true)

      expect(html).to include(public_link)
      expect(html).to include(edit_path_link)
      expect(html).to include('fr-badge--success')
    end
  end

  context 'with metadata for a draft procedure' do
    let(:created_at) { Time.zone.parse('2023-03-05') }
    let(:procedure) do
      instance_double('Procedure',
                      libelle: 'Procédure brouillon',
                      close?: false,
                      closed_at: nil,
                      locked?: false,
                      path: 'brouillon',
                      api_entreprise_token: instance_double('Token', expired_or_expires_soon?: false),
                      published_at: nil,
                      created_at: created_at,
                      id: 12)
    end

    before do
      assign(:procedure, procedure)
    end

    it 'displays the draft status' do
      html = render_partial(metadatas: true)

      expect(html).to include('fr-badge--new')
      expect(html).to include(I18n.l(created_at.to_date))
    end
  end
end
