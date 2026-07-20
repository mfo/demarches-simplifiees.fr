# frozen_string_literal: true

class Dossiers::FranceConnectChampComponent < ApplicationComponent
  delegate :fc_data_correct?, :fc_data_incorrect?, :fc_data_not_found?, to: :@champ

  attr_reader :champ, :profile

  def initialize(champ:, profile:)
    @champ = champ
    @profile = profile
  end

  def call
    safe_join([
      notice,
      champ_content,
    ])
  end

  private

  def notice
    if profile == 'instructeur'
      render Dsfr::NoticeComponent.new(
        closable: false,
        data_attributes: { "data-notice-name" => "info-recuperation-donnees", class: 'clearfix' }
      ) do |c|
        c.with_title do
          description
        end
      end
    end
  end

  def description
    if fc_data_correct?
      t(".fc_data_correct", type_champ:)
    elsif fc_data_incorrect?
      t(".fc_data_incorrect", type_champ:)
    elsif fc_data_not_found?
      t(".fc_data_not_found", type_champ:)
    else
      t(".fc_data_not_recovered", type_champ:)
    end
  end

  def champ_content
    if fc_data_correct?
      render FranceConnectChamp::ExternalChampComponent.new(type_champ: champ.type_champ, data: champ.value_json['api_part'], with_header: false)
    else
      render partial: "shared/champs/piece_justificative/show", locals: { champ:, profile: }
    end
  end

  def type_champ
    t(".type_champ.#{champ.type_champ}")
  end
end
