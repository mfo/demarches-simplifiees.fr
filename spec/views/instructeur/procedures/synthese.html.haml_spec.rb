# frozen_string_literal: true

describe 'instructeurs/procedures/synthese', type: :view do
  subject do
    render template: 'instructeurs/procedures/synthese', locals: { all_dossiers_counts: }
  end

  let(:all_dossiers_counts) do
    {
      'a-suivre' => 4,
      'suivis' => 0,
      'traites' => 2,
      'tous' => 6
    }
  end

  it { is_expected.to have_css('dialog#instructeur-dossiers-synthesis-modal-dialog.fr-modal') }
  it { is_expected.to have_text('Synthèse des dossiers') }
  it { is_expected.to have_text('à suivre') }
  it { is_expected.to have_text('traités') }
  it { is_expected.to have_text('au total') }
  it { is_expected.not_to have_text('suivis par moi') }
end
