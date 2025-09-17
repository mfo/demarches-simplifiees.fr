# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'
require 'pathname'

module ViewSnapshot
  SNAPSHOT_DIR = Rails.root.join('spec', 'views', 'snapshots').freeze
  FAILURE_LOG = Rails.root.join('spec.failures').freeze

  module_function

  def snapshot_mode?
    ENV['SNAPSHOT'] == '1'
  end

  def check_mode?
    ENV['CHECK_SNAPSHOT'] == '1'
  end

  def handle(example, html)
    return if html.nil? || html.empty?

    if snapshot_mode?
      save_snapshot(example, html)
    elsif check_mode?
      compare_snapshot(example, html)
    end
  end

  def save_snapshot(example, html)
    path = snapshot_path(example)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, html)
  end

  def compare_snapshot(example, html)
    path = snapshot_path(example)
    unless path.exist?
      record_failure(path.basename.to_s)
      raise RSpec::Expectations::ExpectationNotMetError, "Snapshot missing for #{path.basename}"
    end

    current_structure = html_structure(html)
    stored_structure = html_structure(path.read)

    return if current_structure == stored_structure

    record_failure(path.basename.to_s)

    raise RSpec::Expectations::ExpectationNotMetError,
          "Snapshot mismatch for #{path.basename}"
  end

  def record_failure(snapshot_name)
    existing = FAILURE_LOG.exist? ? FAILURE_LOG.read.split(/\r?\n/) : []
    return if existing.include?(snapshot_name)

    File.open(FAILURE_LOG, 'a') { |file| file.puts(snapshot_name) }
  end

  def snapshot_path(example)
    spec_name = spec_identifier(example)
    example_name = sanitize_example_description(example.metadata[:description].to_s)
    line = example.metadata[:line_number]

    SNAPSHOT_DIR.join("#{spec_name}_it_#{example_name}-#{line}.html")
  end

  def spec_identifier(example)
    spec_path = Pathname.new(example.metadata[:file_path])
    relative = spec_path.relative_path_from(Rails.root.join('spec'))
    relative.sub_ext('').to_s.tr('/', '_')
  rescue ArgumentError
    spec_path.basename.sub_ext('').to_s
  end

  def sanitize_example_description(description)
    sanitized = description.downcase.gsub(/[^a-z0-9]+/, '_')
    sanitized = sanitized.gsub(/\d+/, '')
    sanitized = sanitized.gsub(/_+/, '_').gsub(/^_+|_+$/, '')
    sanitized.empty? ? 'example' : sanitized
  end

  def html_structure(html)
    fragment = Nokogiri::HTML.fragment(html)
    fragment.children.map { |node| canonical_node(node) }.compact
  end

  def canonical_node(node)
    return nil if node.comment?

    if node.element?
      attribute_names = node.attribute_nodes.map(&:name).reject { |name| name == 'id' }
      [
        node.name,
        attribute_names.sort,
        node.children.map { |child| canonical_node(child) }.compact
      ]
    else
      nil
    end
  end
end

RSpec.configure do |config|
  config.after(:each, type: :view) do |example|
    next unless example.respond_to?(:example_group_instance)

    instance = example.example_group_instance
    html = instance.instance_variable_get(:@rendered)
    ViewSnapshot.handle(example, html)
  end
end
