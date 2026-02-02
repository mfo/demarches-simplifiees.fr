# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "LLM::CleanerImprover Evaluation", :llm_eval do
  let(:runner) { LLM::Runner.new }

  def evaluate_fixture(fixture_filename)
    fixture_path = Rails.root.join("spec/fixtures/llm_eval/cleaner_improver/#{fixture_filename}")
    test_case = YAML.load_file(fixture_path).with_indifferent_access

    # Create test procedure and suggestion
    procedure = FactoryBot.create(:procedure, test_case[:procedure_params].deep_symbolize_keys.merge(service: FactoryBot.create(:service)))
    suggestion = FactoryBot.create(:llm_rule_suggestion, procedure_revision: procedure.draft_revision, rule: 'cleaner')

    # Call the real CleanerImprover
    service = LLM::CleanerImprover.new(runner: runner)
    tool_calls, _usage = service.generate_for(suggestion)

    # Extract and compare destroyed stable_ids
    actual_destroys = tool_calls.map { _1[:stable_id] }.compact.sort
    expected_destroys = (test_case[:expected_destroys] || []).map { _1[:stable_id] }.sort

    # Display result
    puts "\n📋 Test Case: #{test_case[:name]}"
    puts "Expected: #{expected_destroys.inspect}"
    puts "Actual:   #{actual_destroys.inspect}"
    puts "Status: #{actual_destroys == expected_destroys ? '✅ PASS' : '❌ FAIL'}"

    {
      actual_destroys: actual_destroys,
      expected_destroys: expected_destroys,
      passed: actual_destroys == expected_destroys,
      tool_calls: tool_calls,
    }
  end

  it "Adresse + Commune redondante" do
    result = evaluate_fixture('001_address_commune.yml')

    expect(result[:actual_destroys]).to eq(result[:expected_destroys]),
      "Expected: #{result[:expected_destroys].inspect}, Got: #{result[:actual_destroys].inspect}"
  end

  it "SIRET + Raison sociale redondante pour une demarche adressée a des personne morale" do
    result = evaluate_fixture('002_siret_raison_sociale.yml')

    expect(result[:actual_destroys]).to eq(result[:expected_destroys]),
      "Expected: #{result[:expected_destroys].inspect}, Got: #{result[:actual_destroys].inspect}"
  end
end
