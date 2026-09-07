# frozen_string_literal: true

describe RejectNullByteParams, type: :request do
  it 'rejects a form value containing a null byte' do
    post '/users/sign_in', params: { user: { email: 'usager@example.com', password: "x\0y" } }

    expect(response).to have_http_status(:bad_request)
  end

  it 'rejects a JSON body containing a null byte' do
    blob = { filename: "x\0.pdf", byte_size: 1, checksum: 'a', content_type: 'text/plain' }
    post '/rails/active_storage/direct_uploads', params: { blob: }.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }

    expect(response).to have_http_status(:bad_request)
  end

  it 'rejects a query parameter containing a null byte' do
    get '/contact', params: { origin: "x\0y" }

    expect(response).to have_http_status(:bad_request)
  end

  it 'lets other requests through' do
    get '/contact', params: { origin: 'autosave' }

    expect(response).to have_http_status(:ok)
  end
end
