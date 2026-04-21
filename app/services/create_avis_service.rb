# frozen_string_literal: true

class CreateAvisService
  def self.call(claimant:, batch:, avis:, emails:, avis_source: nil)
    new(claimant, batch, avis, emails, avis_source).call
  end

  def initialize(claimant, batch, avis, emails, avis_source = nil)
    @dossier = avis.dossier
    @claimant = claimant
    @batch = batch
    @avis = avis
    @avis_source = avis_source
    @emails = emails
  end

  def call
    confidentiel = @avis_source&.confidentiel || @avis.confidentiel || false
    introduction_file_change = @avis.attachment_changes["introduction_file"]
    introduction_file = introduction_file_change.attachable if introduction_file_change.is_a?(ActiveStorage::Attached::Changes::CreateOne)

    allowed_dossiers = [@dossier]

    if @avis.invite_linked_dossiers.present?
      allowed_dossiers += @dossier.linked_dossiers_for(@claimant)
    end

    if @claimant.is_a?(Instructeur) &&
       !@claimant.follows.exists?(dossier: @dossier)
      @claimant.follow(@dossier)
    end

    users, invalids = @emails.map { User.create_or_promote_to_expert(it, SecureRandom.hex) }.partition(&:valid?)
    failed_emails = invalids.map { { email: it.email, messages: it.errors.full_messages } }

    experts = users.map(&:expert)
    experts_procedures_h = allowed_dossiers.map(&:procedure).uniq
      .flat_map { |procedure| experts.map { |expert| [[expert, procedure], ExpertsProcedure.find_or_create_by(procedure: dossier.procedure, expert: user.expert)] } }
      .to_h

    avis_params = experts.flat_map do |expert|
      allowed_dossiers.map do |dossier|
        {
          introduction: @avis.introduction,
          introduction_file:,
          claimant: @claimant,
          dossier:,
          confidentiel:,
          experts_procedure: experts_procedures_h[[expert, dossier.procedure]],
          question_label: @avis.question_label,
        }
      end
    end

    create_results = Avis.create(avis_params)

    persisted, failed = create_results.partition(&:persisted?)

    failed_emails += failed.map { |avis| { email: avis.expert.email, messages: avis.errors.full_messages } }

    if persisted.any?
      @dossier.touch(:last_avis_updated_at)

      if @claimant.is_a?(Instructeur)
        follow = @claimant.follows.find_by(dossier: @dossier)
        follow&.update_column(:avis_seen_at, Time.current)

        DossierNotification.create_notification(@dossier, :attente_avis)
        @claimant.mark_tab_as_seen(@dossier, :avis)
      end
    end

    @dossier.avis.reload

    persisted.each { |avis| avis.dossier.demander_un_avis!(avis) }

    sent_emails = persisted.filter { it.dossier == @dossier }.map do |avis|
      if avis.experts_procedure.notify_on_new_avis? && !@batch
        avis.expert.user.invite_expert_and_send_avis!(avis)
      end
      avis.expert.email
    end

    [sent_emails.uniq, failed_emails]
  end
end
