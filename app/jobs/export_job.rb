# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :exports

  use_sidekiq_retry

  discard_on ActiveRecord::RecordNotFound

  def perform(export)
    return if export.generated?

    Sentry.set_tags(procedure: export.procedure.id, export: export.id)
    Sentry.set_extras(export_format: export.format, export_template_id: export.export_template_id)

    if Rails.env.development?
      # Set URL options for ActiveStorage
      ActiveStorage::Current.url_options = Rails.application.routes.default_url_options
    end

    export.compute_with_safe_stale_for_purge do
      export.compute
    end
  end
end
