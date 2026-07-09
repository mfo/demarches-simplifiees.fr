# frozen_string_literal: true

module ChampRevisionConcern
  extend ActiveSupport::Concern

  protected

  def in_dossier_revision?
    dossier.stable_id_in_revision?(stable_id)
  end
end
