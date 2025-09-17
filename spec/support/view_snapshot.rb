# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'
require 'pathname'

module ViewSnapshot
  SNAPSHOT_DIR = Rails.root.join('spec', 'snapshots')
  SPEC_FAILURES_PATH = Rails.root.join('spec.failures')

  class << self
    def mode
      return @mode if defined?(@mode)

      @mode = if ENV['SNAPSHOT'].present?
                :record
              elsif ENV['CHECK_SNAPSHOT'].present?
                :check
              end
    end

    def active?
      mode.present?
    end

    def handle_example(example, html)
      return unless active?

      case mode
      when :record
        save_snapshot(example, html)
      when :check
        check_snapshot(example, html)
      end
    end

    def record_failure(path)
      failures << path unless failures.include?(path)
    end

    def failures
      @failures ||= []
    end

    def flush_failures
      return unless mode == :check

      if failures.any?
        File.write(SPEC_FAILURES_PATH, failures.join("\n") + "\n")
      elsif File.exist?(SPEC_FAILURES_PATH)
        File.delete(SPEC_FAILURES_PATH)
      end
    end

    private

    def save_snapshot(example, html)
      FileUtils.mkdir_p(SNAPSHOT_DIR)
      File.write(snapshot_file(example), html)
    end

    def check_snapshot(example, html)
      snapshot_path = snapshot_file(example)

      unless File.exist?(snapshot_path)
        record_failure(relative_path(snapshot_path))
        raise RSpec::Expectations::ExpectationNotMetError, "Snapshot missing for #{relative_path(snapshot_path)}"
      end

      stored_html = File.read(snapshot_path)
      unless html_structure(html) == html_structure(stored_html)
        record_failure(relative_path(snapshot_path))
        raise RSpec::Expectations::ExpectationNotMetError, "Snapshot mismatch for #{relative_path(snapshot_path)}"
      end
    end

    def snapshot_file(example)
      FileUtils.mkdir_p(SNAPSHOT_DIR)
      SNAPSHOT_DIR.join(snapshot_filename(example))
    end

    def snapshot_filename(example)
      spec_path = example.metadata[:file_path]
      relative_spec = begin
        Pathname(spec_path).relative_path_from(Rails.root.join('spec')).to_s
      rescue StandardError
        File.basename(spec_path)
      end

      spec_name = relative_spec.tr(File::SEPARATOR, '__').sub(/\.rb\z/, '')
      line_number = example.metadata[:line_number] || example.metadata[:location]&.split(':')&.last
      line_number = line_number.to_s
      line_number = 'unknown' if line_number.blank?
      sanitized_description = sanitize_description(example.metadata[:description])

      "#{spec_name}_it_#{sanitized_description}-#{line_number}.html"
    end

    def sanitize_description(description)
      sanitized = description.to_s.downcase
      sanitized = sanitized.gsub(/\d+/, '')
      sanitized = sanitized.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
      sanitized = 'example' if sanitized.blank?
      sanitized
    end

    def html_structure(html)
      fragment = Nokogiri::HTML.fragment(html.to_s)
      fragment.children.filter_map { |node| node_structure(node) }
    end

    def node_structure(node)
      return nil unless node.element?

      [node.name, node.children.filter_map { |child| node_structure(child) }]
    end

    def relative_path(path)
      Pathname(path).relative_path_from(Rails.root).to_s
    end
  end
end

if ViewSnapshot.active?
  RSpec.configure do |config|
    config.after(:each, type: :view) do |example|
      next unless defined?(rendered)
      next if rendered.blank?

      ViewSnapshot.handle_example(example, rendered)
    end

    config.after(:suite) do
      ViewSnapshot.flush_failures
    end
  end
end
