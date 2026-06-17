# frozen_string_literal: true

module Maintenance
  class T20260615StripUnderlineMarksFromTiptapBodiesTask < MaintenanceTasks::Task
    # PR #13293 removed the underline button from the attestation editors, so the
    # Tiptap `Underline` extension is no longer loaded. Opening an attestation
    # whose stored json_body still contains an underline mark would then crash the
    # editor: ProseMirror raises "Unknown mark type: underline" while parsing the
    # JSON content, leaving the editor unmounted.
    #
    # This task strips every "underline" mark from the stored json_body of both
    # editors (attestation v2 and "attestation de dépôt").

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Must run during the deploy that ships PR #13293, otherwise admins could open
    # an underlined attestation with the new (underline-less) editor and crash it.
    run_on_first_deploy

    def collection
      AttestationTemplate.where(contains_underline_mark).order(:id).to_a +
        DossierSubmittedMessage.where(contains_underline_mark).order(:id).to_a
    end

    def process(record)
      cleaned = strip_underline_marks(record.json_body)
      record.update_column(:json_body, cleaned) if cleaned != record.json_body
    end

    def count
      collection.size
    end

    private

    def contains_underline_mark
      ["json_body::text LIKE ?", '%"underline"%']
    end

    def strip_underline_marks(node)
      case node
      when Array
        node.map { strip_underline_marks(_1) }
      when Hash
        node.each_with_object({}) do |(key, value), result|
          if key == "marks" && value.is_a?(Array)
            kept = value.reject { _1.is_a?(Hash) && _1["type"] == "underline" }
            result[key] = kept if kept.any?
          else
            result[key] = strip_underline_marks(value)
          end
        end
      else
        node
      end
    end
  end
end
