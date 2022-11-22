# == Schema Information
#
# Table name: batch_operations
#
#  id                  :bigint           not null, primary key
#  failed_dossier_ids  :bigint           default([]), not null, is an Array
#  finished_at         :datetime
#  operation           :string           not null
#  payload             :jsonb            not null
#  run_at              :datetime
#  success_dossier_ids :bigint           default([]), not null, is an Array
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  instructeur_id      :bigint           not null
#

class BatchOperation < ApplicationRecord
  enum operation: {
    archiver: 'archiver',
    accepter: 'accepter'
  }

  has_many :dossiers, dependent: :nullify
  belongs_to :instructeur
  has_one_attached :justificatif_motivation

  validates :operation, presence: true

  def enqueue_all
    dossiers_safe_scope
      .map { |dossier| BatchOperationProcessOneJob.perform_later(self, dossier) }
  end

  def process_one(dossier)
    case operation
    when BatchOperation.operations.fetch(:archiver) then
      dossier.archiver!(instructeur)
    when BatchOperation.operations.fetch(:accepter) then
      dossier.accepter!({ instructeur: instructeur, motivation: payload["motivation"], justificatif: justificatif_motivation&.blob })
    end
    true
  rescue
    false
  end

  def called_for_first_time?
    run_at.nil?
  end

  def called_for_last_time? # beware, must be reloaded first
    dossiers.count.zero?
  end

  private

  # safer enqueue, in case instructeur kept the page for some time and their is a Dossier.id which does not fit current transaction
  def dossiers_safe_scope
    query = Dossier.joins(:procedure)
      .where(procedure: { id: instructeur.procedures.ids })
      .where(id: dossiers.ids)
      .visible_by_administration
    case operation
    when BatchOperation.operations.fetch(:archiver) then
      query.not_archived
    when BatchOperation.operations.fetch(:accepter) then
      query.state_en_instruction
    end
  end
end
