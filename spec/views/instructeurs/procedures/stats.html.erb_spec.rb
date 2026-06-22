# frozen_string_literal: true

describe 'shared/procedures/_stats', type: :view do
  let(:procedure) { create(:procedure) }
  let(:usual_traitement_time) { [1.day, 5.days, 1.month] }

  before do
    assign(:procedure, procedure)
    assign(:usual_traitement_time, usual_traitement_time)
    allow(procedure).to receive(:stats_usual_traitement_time).and_return(usual_traitement_time)
  end

  context 'when rendered from instructeur view (show_user_indication: true)' do
    subject { render partial: 'shared/procedures/stats', locals: { title: 'Statistiques', show_user_indication: true } }

    it 'shows "(indiqué aux usagers)" in the usual processing time title' do
      expect(subject).to have_text("Temps de traitement usuel")
      expect(subject).to have_text("(indiqué aux usagers)")
    end
  end

  context 'when rendered from usager view (show_user_indication not set)' do
    subject { render partial: 'shared/procedures/stats', locals: { title: 'Statistiques' } }

    it 'does not show "(indiqué aux usagers)"' do
      expect(subject).not_to have_text("indiqué aux usagers")
    end
  end

  context 'when estimated_processing_duration_visible is false' do
    let(:procedure) { create(:procedure, estimated_processing_duration_visible: false) }

    context 'from instructeur view' do
      subject { render partial: 'shared/procedures/stats', locals: { title: 'Statistiques', show_user_indication: true } }

      it 'still shows the callout with "(indiqué aux usagers)"' do
        expect(subject).to have_text("Temps de traitement usuel")
        expect(subject).to have_text("(indiqué aux usagers)")
      end
    end

    context 'from usager view' do
      subject { render partial: 'shared/procedures/stats', locals: { title: 'Statistiques' } }

      it 'does not show the callout' do
        expect(subject).not_to have_text("Temps de traitement usuel")
      end
    end
  end
end
