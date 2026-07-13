# frozen_string_literal: true

module ChampStreamConcern
  extend ActiveSupport::Concern

  def main_stream?
    stream == Dossier::MAIN_STREAM
  end

  def user_buffer_stream?
    stream == Dossier::USER_BUFFER_STREAM
  end

  def instructeur_buffer_stream?
    stream == Dossier::INSTRUCTEUR_BUFFER_STREAM
  end

  def history_stream?
    stream.start_with?(Dossier::HISTORY_STREAM)
  end

  def buffer_stream?
    persisted? && (user_buffer_stream? || instructeur_buffer_stream?)
  end

  def instructeur_buffer_source_stream?
    source_stream == Dossier::INSTRUCTEUR_BUFFER_STREAM
  end
end
