class BatchOperationJob < ApplicationJob
  # what about wrapping all of that in a transaction
  # but, what about nested transaction because batch_operation.process_one(dossier) can run transaction
  def perform(batch_operation, dossier)
    success = batch_operation.process_one(dossier)
    dossier.update(batch_operation: nil)
    batch_operation.reload # reload before deciding if it has been finished
    batch_operation.run_at = Time.zone.now if batch_operation.called_for_first_time?
    batch_operation.finished_at = Time.zone.now if batch_operation.called_for_last_time?
    batch_operation.send(success ? :success_dossier_ids : :failed_dossier_ids).push(dossier.id)
    batch_operation.save!
  end
end
