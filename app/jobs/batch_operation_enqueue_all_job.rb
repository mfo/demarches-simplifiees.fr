# frozen_string_literal: true

class BatchOperationEnqueueAllJob < ApplicationJob
  def perform(batch_operation)
    batch_operation.enqueue_all
  end
end
