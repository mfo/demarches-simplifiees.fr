class Cron::PurgeStaleBatchOperationJob < Cron::CronJob
  self.schedule_expression = "every 5 minutes"

  def perform
    BatchOperation.stale(BatchOperation::RETENTION_DURATION).destroy_all
    BatchOperation.stuck(BatchOperation::MAX_DUREE_GENERATION).destroy_all
  end
end
