# frozen_string_literal: true

module ArchiveHelper
  def estimate_weight(archive, nb_dossiers_termines, average_dossier_weight)
    if archive.present? && archive.available?
      archive.file.byte_size
    elsif !average_dossier_weight.nil?
      nb_dossiers_termines * average_dossier_weight
    end
  end
end
