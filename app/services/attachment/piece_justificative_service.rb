# frozen_string_literal: true

class Attachment::PieceJustificativeService
  def self.attach(champ, blob_signed_id)
    ActiveStorage::Attachment.transaction do
      champ.piece_justificative_file.attach(blob_signed_id)
      context = champ.public? ? :champs_public_value : :champs_private_value
      champ.save(context:)
    end
  end
end
