# frozen_string_literal: true

describe NavBarProfile do
  describe '.all' do
    subject { described_class.all }

    it 'orders profiles from the most specific to the least' do
      expect(subject.last).to eq(:user)
      expect(subject.index(:administrateur)).to be < subject.index(:instructeur)
    end

    context 'when the admins group feature is enabled' do
      before { allow(Rails.application.config).to receive(:ds_admins_group_enabled).and_return(true) }

      it { is_expected.to include(:gestionnaire) }
    end

    context 'when the admins group feature is disabled' do
      before { allow(Rails.application.config).to receive(:ds_admins_group_enabled).and_return(false) }

      it 'drops the gestionnaire profile and keeps every other one' do
        is_expected.not_to include(:gestionnaire)
        is_expected.to include(:user, :instructeur, :expert, :administrateur)
      end
    end
  end

  describe '.roles' do
    subject { described_class.roles }

    it 'is every profile but :user' do
      expect(subject).to eq(described_class.all - [:user])
    end
  end
end
