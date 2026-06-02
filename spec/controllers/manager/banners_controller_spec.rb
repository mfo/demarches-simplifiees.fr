# frozen_string_literal: true

describe Manager::BannersController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  before { sign_in super_admin }

  render_views

  describe 'GET #index' do
    let!(:banner) { Banner.create!(target: 'global', content: 'Message global') }

    it 'liste les bannières' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Banner::TARGET_LABELS['global'])
    end
  end

  describe 'PATCH #update' do
    let(:banner) { Banner.create!(target: 'global', content: '') }

    it 'publie en renseignant le contenu' do
      patch :update, params: { id: banner.id, banner: { content: 'Nouveau message' } }

      expect(banner.reload.content).to eq('Nouveau message')
      expect(banner).to be_active
    end

    it 'dépublie en vidant le contenu' do
      banner.update!(content: 'Ancien')

      patch :update, params: { id: banner.id, banner: { content: '' } }

      expect(banner.reload.content).to eq('')
      expect(banner).not_to be_active
    end
  end
end
