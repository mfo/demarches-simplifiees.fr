# frozen_string_literal: true

class CreateAvisService
  Result = Data.define(:avis, :sent_emails, :failed_emails)

  def self.call(dossier:, instructeur_or_expert:, batch:, params:, avis_source: nil)
    new(dossier, instructeur_or_expert, batch, params, avis_source).call
  end

  def initialize(dossier, instructeur_or_expert, batch, params, avis_source = nil)
    @dossier = dossier
    @instructeur_or_expert = instructeur_or_expert
    @batch = batch
    @params = params
    @avis_source = avis_source
  end

  def call
    if @params[:emails].blank? || @params[:emails].all?(&:blank?)
      avis = Avis.new(@params)
      blank_message = format(I18n.t('errors.format'), attribute: User.human_attribute_name(:email), message: I18n.t('errors.messages.blank'))
      return Result.new(avis, [], [{ email: nil, messages: [blank_message] }])
    end

    confidentiel = @avis_source&.confidentiel || @params[:confidentiel] || false

    emails = Array(@params[:emails]).map(&:strip).map(&:downcase).uniq.compact_blank
    allowed_dossiers = [@dossier]

    if @params[:invite_linked_dossiers].present?
      allowed_dossiers += @dossier.linked_dossiers_for(@instructeur_or_expert)
    end

    if @instructeur_or_expert.is_a?(Instructeur) &&
       !@instructeur_or_expert.follows.exists?(dossier: @dossier)
      @instructeur_or_expert.follow(@dossier)
    end

    users, invalids = emails.map { User.create_or_promote_to_expert(it, SecureRandom.hex) }.partition(&:valid?)
    failed_emails = invalids.map { { email: it.email, messages: it.errors.full_messages } }

    experts = users.map(&:expert)
    experts_procedures_h = allowed_dossiers.map(&:procedure).uniq
      .flat_map { |procedure| experts.map { |expert| [[expert, procedure], ExpertsProcedure.find_or_create_by(procedure: dossier.procedure, expert: user.expert)] } }
      .to_h

    avis_params = experts.flat_map do |expert|
      allowed_dossiers.map do |dossier|
        {
          introduction: @params[:introduction],
          introduction_file: @params[:introduction_file],
          claimant: @instructeur_or_expert,
          dossier: dossier,
          confidentiel: confidentiel,
          experts_procedure: experts_procedures_h[[expert, dossier.procedure]],
          question_label: @params[:question_label],
        }
      end
    end

    create_results = Avis.create(avis_params)

    persisted, failed = create_results.partition(&:persisted?)

    failed_emails += failed.map { |avis| { email: avis.expert.email, messages: avis.errors.full_messages } }

    if persisted.any?
      @dossier.touch(:last_avis_updated_at)

      if @instructeur_or_expert.is_a?(Instructeur)
        follow = @instructeur_or_expert.follows.find_by(dossier: @dossier)
        follow&.update_column(:avis_seen_at, Time.current)

        DossierNotification.create_notification(@dossier, :attente_avis)
        @instructeur_or_expert.mark_tab_as_seen(@dossier, :avis)
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

    avis_result = persisted.first || failed.first || Avis.new(@params)

    Result.new(avis_result, sent_emails.uniq, failed_emails)
  end
end
