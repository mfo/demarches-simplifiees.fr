# frozen_string_literal: true

class CommentaireService
  def self.create(sender, dossier, params)
    save(dossier, prepare_params(sender, params))
  end

  def self.create!(sender, dossier, params)
    save!(dossier, prepare_params(sender, params))
  end

  def self.build(sender, dossier, params)
    dossier.commentaires.build(prepare_params(sender, params))
  end

  def self.prepare_params(sender, params)
    case sender
    when String
      params[:email] = sender
    when Instructeur
      params[:instructeur] = sender
      params[:email] = sender.email
    when Expert
      params[:expert] = sender
      params[:email] = sender.email
    else
      params[:email] = sender.email
    end

    # For some reason ActiveStorage trows an error in tests if we passe an empty string here.
    # I suspect it could be resolved in rails 6 by using explicit `attach()`
    if params[:piece_jointe].blank?
      params.delete(:piece_jointe)
    end

    params
  end

  def self.save(dossier, params)
    build_and_save(dossier, params)
  end

  def self.save!(dossier, params)
    build_and_save(dossier, params, raise_exception: true)
  end

  def self.build_and_save(dossier, params, raise_exception: false)
    message = dossier.commentaires.build(params)
    if raise_exception
      message.save!
    else
      message.save
      message
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    # Assigning piece_jointe verifies the signed ids sent by the direct upload,
    # which BlobSignedIdConcern makes valid for one hour: the form stayed open
    # too long, or an id was tampered with. Either way the file has to be
    # selected again; the message is kept so the user does not lose it.
    message = dossier.commentaires.build(params.except(:piece_jointe))
    message.errors.add(:piece_jointe, :attachment_expired)
    raise ActiveRecord::RecordInvalid, message if raise_exception

    message
  end
end
