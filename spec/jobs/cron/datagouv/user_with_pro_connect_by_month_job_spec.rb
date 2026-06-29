# frozen_string_literal: true

RSpec.describe Cron::Datagouv::UserWithProConnectByMonthJob, type: :job do
  describe 'data_for' do
    let(:month) { Date.parse('01/01/2024') }

    subject { Cron::Datagouv::UserWithProConnectByMonthJob.new.send(:data_for, month:) }

    context 'when a new user is created with ProConnect' do
      let!(:user_witout_pro_connect) { create(:user, created_at: Date.parse('15/01/2024')) }
      let!(:user_with_pro_connect) { create(:user, created_at: Date.parse('15/01/2024')) }
      let!(:pci) { create(:pro_connect_information, user: user_with_pro_connect, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 1, 0, 0, 0, 0, 0]) }
    end

    context 'when a new instructeur is created with ProConnect' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2024')) }
      let!(:instructeur) { create(:instructeur, user:, created_at: Date.parse('15/01/2024')) }
      let!(:pci) { create(:pro_connect_information, user:, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 0, 1, 0, 0, 0, 0]) }
    end

    context 'when a new administrateur is created with ProConnect' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2024')) }
      let!(:instructeur) { create(:instructeur, user:, created_at: Date.parse('15/01/2024')) }
      let!(:administrateur) { create(:administrateur, user:, created_at: Date.parse('15/01/2024')) }
      let!(:pci) { create(:pro_connect_information, user:, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 0, 0, 1, 0, 0, 0]) }
    end

    context 'when an existing user is converted on Pro Connect' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2023')) }
      let!(:pci) { create(:pro_connect_information, user:, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 0, 0, 0, 1, 0, 0]) }
    end

    context 'when an existing instructeur is converted on Pro Connect' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2023')) }
      let!(:instructeur) { create(:instructeur, user:, created_at: Date.parse('15/01/2023')) }
      let!(:pci) { create(:pro_connect_information, user:, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 0, 0, 0, 0, 1, 0]) }
    end

    context 'when an existing administrateur is converted on Pro Connect' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2023')) }
      let!(:instructeur) { create(:instructeur, user:, created_at: Date.parse('15/01/2023')) }
      let!(:administrateur) { create(:administrateur, user:, created_at: Date.parse('15/01/2023')) }
      let!(:pci) { create(:pro_connect_information, user:, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 0, 0, 0, 0, 0, 1]) }
    end

    context 'when an existing instructeur is promoted, and then logs with Pro Connect' do
      let!(:user) { create(:user, created_at: Date.parse('15/01/2023')) }
      let!(:instructeur) { create(:instructeur, user:, created_at: Date.parse('15/01/2023')) }
      let!(:administrateur) { create(:administrateur, user:, created_at: Date.parse('15/01/2024')) }
      let!(:pci) { create(:pro_connect_information, user:, created_at: Date.parse('15/01/2024')) }

      it { is_expected.to eq(['2024-01', 0, 0, 1, 0, 0, 0]) }
    end
  end
end
