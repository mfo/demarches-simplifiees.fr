# frozen_string_literal: true

require 'rails_helper'

describe 'administrateurs/login_banner', type: :view do
  it 'renders the sign out link' do
    render partial: 'administrateurs/login_banner'

    expect(rendered).to include('/administrateurs/sign_out')
  end
end
