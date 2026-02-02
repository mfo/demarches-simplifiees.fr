# frozen_string_literal: true

module LLM
  module Eval
    module EvalHelper
      # Display evaluation result
      def self.display_result(result)
        puts "\n📋 Test Case: #{result[:test_case][:name]}"
        puts "Expected: #{result[:expected_destroys].inspect}"
        puts "Actual:   #{result[:actual_destroys].inspect}"
        puts "Status: #{result[:passed] ? '✅ PASS' : '❌ FAIL'}"
      end
    end
  end
end
