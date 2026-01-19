# frozen_string_literal: true

class Champs::PieceJustificativeController < Champs::ChampController
  before_action :ensure_legitimate_access

  def show
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to(root_url) }
    end
  end

  def update
    if attach_piece_justificative
      render :show
    else
      render json: { errors: @champ.errors.full_messages }, status: 422
    end
  end

  def template
    redirect_to rails_blob_url(@champ.type_de_champ.piece_justificative_template.blob, disposition: 'attachment')
  end

  private

  def ensure_legitimate_access
    return if @champ.piece_justificative? || @champ.quotient_familial?

    head :not_found
  end

  def attach_piece_justificative
    save_succeed = Attachment::PieceJustificativeService.attach_champ_pj(@champ, params[:blob_signed_id])

    if save_succeed
      @champ.update_timestamps
    end

    save_succeed
  end
end
