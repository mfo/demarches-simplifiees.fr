# frozen_string_literal: true

require 'haml_lint'
require 'haml_lint/spec'
require_relative '../../../lib/linters/output_safety_linter'

RSpec.describe HamlLint::Linter::OutputSafetyLinter do
  include_context 'linter'

  context 'when the markup is tagged safe by hand' do
    let(:haml) { '= body.html_safe' }

    it { is_expected.to report_lint line: 1 }
  end

  context 'when `raw` bypasses the escaping' do
    let(:haml) { '= raw(body)' }

    it { is_expected.to report_lint line: 1 }
  end

  context 'when `html_safe?` only asks whether the string is already safe' do
    let(:haml) do
      <<~HAML
        - if body.html_safe?
          %p= body
      HAML
    end

    it { is_expected.not_to report_lint }
  end

  context 'when nothing bypasses the escaping' do
    let(:haml) { '%p= t(".body_html")' }

    it { is_expected.not_to report_lint }
  end
end
