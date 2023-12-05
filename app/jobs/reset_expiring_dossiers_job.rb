class ResetExpiringDossiersJob < ApplicationJob
  def perform(procedure)
    procedure
      .dossiers
      .select(:id, :brouillon_close_to_expiration_notice_sent_at, :en_construction_close_to_expiration_notice_sent_at, :termine_close_to_expiration_notice_sent_at)
      .in_batches do |relation|
        to_update = relation.filter(&:expiration_started?)
        Dossier.where(id: to_update.map(&:id))
          .update_all(brouillon_close_to_expiration_notice_sent_at: nil,
                            en_construction_close_to_expiration_notice_sent_at: nil,
                            termine_close_to_expiration_notice_sent_at: nil)
      end
  end
end
