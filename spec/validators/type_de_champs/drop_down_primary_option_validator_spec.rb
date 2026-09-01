# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TypeDeChamps::DropDownPrimaryOptionValidator do
  let(:procedure) { create(:procedure, public_type_de_champs: types) }
  let(:type_de_champ) { procedure.active_revision.public_root_type_de_champs.first }

  subject { procedure.validate(:public_type_de_champs_editor) }

  context 'with a linked drop down list' do
    let(:types) { [type: :linked_drop_down_list] }

    context 'when the menu starts with a primary option' do
      before { type_de_champ.update(drop_down_options: ['--Primary--', 'secondary 1', 'secondary 2']) }

      it { expect { subject }.not_to change { procedure.errors.count } }
    end

    context 'with a degenerate but valid menu' do
      before { type_de_champ.update(drop_down_options: ['--Primary--']) }

      it { expect { subject }.not_to change { procedure.errors.count } }
    end

    context 'when the menu starts with a secondary option' do
      before { type_de_champ.update(drop_down_options: ['secondary 1', '--Primary--', 'secondary 2']) }

      it 'adds an error to the procedure' do
        subject

        expect(procedure.errors.messages_for(:public_draft_type_de_champs))
          .to include(I18n.t('activerecord.errors.models.procedure.attributes.public_draft_type_de_champs.missing_primary_option'))
        expect(procedure.errors.map { _1.options[:type_de_champ] }).to include(type_de_champ)
      end
    end

    context 'when the menu has no primary option at all' do
      before { type_de_champ.update(drop_down_options: ['secondary 1', 'secondary 2']) }

      it { expect { subject }.to change { procedure.errors.count }.by(1) }
    end

    context 'when the menu is empty' do
      before { type_de_champ.update(drop_down_options: []) }

      it 'leaves the report to NoEmptyDropDownValidator' do
        subject

        expect(procedure.errors.messages_for(:public_draft_type_de_champs))
          .not_to include(I18n.t('activerecord.errors.models.procedure.attributes.public_draft_type_de_champs.missing_primary_option'))
      end
    end
  end

  context 'with a simple drop down list' do
    let(:types) { [{ type: :drop_down_list, options: ['not a primary option'] }] }

    it { expect { subject }.not_to change { procedure.errors.count } }
  end
end
