# frozen_string_literal: true

describe 'AxePlaywright matcher', js: true do
  scenario 'detects and formats violations' do
    visit new_user_session_path

    expect(page).to be_axe_clean.excluding('footer')

    page.execute_script(<<~JS)
      const img = document.createElement('img');
      img.src = 'missing.png';
      img.id = 'axe-violation';
      document.body.appendChild(img);
    JS

    matcher = be_axe_clean
    expect(matcher.matches?(page)).to be(false)
    expect(matcher.failure_message).to include('image-alt')
    expect(matcher.failure_message).to include('#axe-violation')

    expect(page).to be_axe_clean.excluding('#axe-violation')
    expect(page).to be_axe_clean.within('main')
    expect(page).not_to be_axe_clean.checking_only('image-alt')
    expect(page).to be_axe_clean.skipping('image-alt', 'region')
  end
end
