# frozen_string_literal: true

describe EmailTemplateReplica do
  let(:procedure) { procedures.individual }

  def replica_for(mail) = described_class.find_by(procedure_id: mail.procedure_id, type: mail.class.name)

  it "replicates a newly customized template" do
    mail = create(:email_depose, procedure:, subject: "Objet v1")

    expect(replica_for(mail)).to have_attributes(subject: "Objet v1", body: mail.body)
  end

  # The copy task compares updated_at between the two tables, so the replica has
  # to carry the legacy timestamps, not the time at which it was written.
  it "replicates the legacy timestamps rather than the time of the copy" do
    mail = create(:email_depose, procedure:)
    legacy_time = 2.days.ago.change(usec: 0)
    mail.update_columns(created_at: legacy_time, updated_at: legacy_time)
    described_class.delete_replica(mail)

    described_class.replicate(mail.reload)

    expect(replica_for(mail)).to have_attributes(created_at: legacy_time, updated_at: legacy_time)
  end

  it "replicates a later edit of the same template" do
    mail = create(:email_depose, procedure:, subject: "Objet v1")
    mail.update!(subject: "Objet v2")

    expect(replica_for(mail).subject).to eq("Objet v2")
  end

  it "replicates each type separately" do
    email_depose = create(:email_depose, procedure:)
    email_passe_en_instruction = create(:email_passe_en_instruction, procedure:)

    expect(replica_for(email_depose).type).to eq("Emails::Depose")
    expect(replica_for(email_passe_en_instruction).type).to eq("Emails::PasseEnInstruction")
  end

  it "deletes the replica when the legacy row is destroyed" do
    mail = create(:email_depose, procedure:)

    expect { mail.destroy! }.to change { replica_for(mail) }.to(nil)
  end

  # Nothing reads email_templates yet, so no association cleans up the replica:
  # the legacy `dependent: :destroy` is what keeps the foreign key satisfiable.
  # Reloaded on purpose — a procedure freshly loaded from the DB is what the
  # deletion task actually destroys, and it has no cached association to rely on.
  it "leaves no row behind when the procedure itself is destroyed" do
    destroyable_procedure = create(:procedure)
    create(:email_depose, procedure: destroyable_procedure)

    expect { Procedure.find(destroyable_procedure.id).destroy! }.not_to raise_error
    expect(described_class.where(procedure_id: destroyable_procedure.id)).to be_empty
  end

  # And if a legacy row ever vanishes without its callbacks (raw SQL, delete_all),
  # the replica must not be what makes a procedure undeletable: without the
  # ON DELETE CASCADE on the foreign key, this raises PG::ForeignKeyViolation.
  it "does not make a procedure undeletable when the legacy row vanished without callbacks" do
    destroyable_procedure = create(:procedure)
    mail = create(:email_depose, procedure: destroyable_procedure)
    Emails::Depose.where(id: mail.id).delete_all

    expect { Procedure.find(destroyable_procedure.id).destroy! }.not_to raise_error
    expect(described_class.where(procedure_id: destroyable_procedure.id)).to be_empty
  end

  # Guards the rolling deploy window, when pods reading email_templates and pods
  # writing the legacy tables coexist: the most recently edited row wins.
  it "does not downgrade a replica newer than the legacy row" do
    mail = create(:email_depose, procedure:, subject: "Objet v1")
    described_class.find_by(procedure_id: procedure.id, type: mail.class.name)
      .update!(subject: "écrit après la bascule", updated_at: 1.hour.from_now)

    described_class.replicate(mail)

    expect(replica_for(mail).subject).to eq("écrit après la bascule")
  end
end
