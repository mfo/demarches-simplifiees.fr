# frozen_string_literal: true

RSpec.describe ProcedureHelper, type: :helper do
  describe '#procedure_auto_archive_datetime' do
    let(:auto_archive_date) { Time.zone.local(2020, 8, 2, 12, 00) }
    let(:procedure) { build(:procedure, auto_archive_on: auto_archive_date) }

    subject { procedure_auto_archive_datetime(procedure) }

    it "displays the day before the auto archive date (to account for the '23h59' ending time)" do
      expect(subject).to have_text("1 août 2020 à 23 h 59 (heure de Paris)")
    end
  end

  describe 'can_send_groupe_message?' do
    let(:procedure) { create(:procedure, groupe_instructeurs: [gi1, gi2]) }
    let(:current_instructeur) { create(:instructeur) }
    subject { can_send_groupe_message?(procedure) }

    context 'when current_instructeur is in all procedure.groupes_instructeur' do
      let(:gi1) { create(:groupe_instructeur, instructeurs: [current_instructeur]) }
      let(:gi2) { create(:groupe_instructeur, instructeurs: [current_instructeur]) }
      it { is_expected.to be_truthy }
    end

    context 'when current_instructeur is in all procedure.groupes_instructeur' do
      let(:instructeur2) { create(:instructeur) }
      let(:gi1) { create(:groupe_instructeur, instructeurs: [current_instructeur]) }
      let(:gi2) { create(:groupe_instructeur, instructeurs: [instructeur2]) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#url_or_email_to_lien_dpo rejects dangerous protocols (XSS prevention)' do
    it 'does not return a javascript: URL' do
      procedure = build(:procedure, lien_dpo: 'javascript:alert(1)')
      expect(helper.url_or_email_to_lien_dpo(procedure)).not_to match(/\Ajavascript:/i)
    end

    it 'does not return a JavaScript: URL (mixed case)' do
      procedure = build(:procedure, lien_dpo: 'JavaScript:alert(document.cookie)')
      expect(helper.url_or_email_to_lien_dpo(procedure)).not_to match(/\Ajavascript:/i)
    end

    it 'does not return a data: URL' do
      procedure = build(:procedure, lien_dpo: 'data:text/html,<script>alert(1)</script>')
      expect(helper.url_or_email_to_lien_dpo(procedure)).not_to match(/\Adata:/i)
    end

    it 'returns valid https URLs unchanged' do
      procedure = build(:procedure, lien_dpo: 'https://example.com/dpo')
      expect(helper.url_or_email_to_lien_dpo(procedure)).to eq('https://example.com/dpo')
    end

    it 'returns mailto: for email addresses' do
      procedure = build(:procedure, lien_dpo: 'dpo@example.com')
      expect(helper.url_or_email_to_lien_dpo(procedure)).to start_with('mailto:')
    end
  end

  describe '#estimated_fill_duration_minutes' do
    subject { estimated_fill_duration_minutes(procedure.reload) }

    context 'with champs' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }, { type: :piece_justificative }]) }

      it 'rounds up the duration to the minute' do
        expect(subject).to eq(3)
      end
    end

    context 'without champs' do
      let(:procedure) { create(:procedure) }

      it 'never displays ’zero minutes’' do
        expect(subject).to eq(1)
      end
    end
  end
end
