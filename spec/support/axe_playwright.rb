# frozen_string_literal: true

# `be_axe_clean` for Playwright-driven system specs.
#
# axe-core-rspec's own matcher drives Selenium-specific APIs (window handles,
# timeouts) and cannot run against capybara-playwright-driver. This matcher
# does what @axe-core/playwright does in Node: inject the axe-core source into
# every frame with `evaluate`, call `axe.run`, and read the results back as
# JSON in a single protocol round trip.
#
# It shadows the gem's matcher (included globally by axe-rspec) for `js: true`
# examples only; `chrome: true` examples keep the gem's Selenium integration.
module AxePlaywright
  AXE_SOURCE_PATH = Rails.root.join('node_modules/axe-core/axe.min.js')

  RUN_SCRIPT = <<~JS
    ({ context, options }) =>
      window.axe.run(context || document, options).then((results) => JSON.parse(JSON.stringify(results)))
  JS

  class BeAxeClean
    def initialize
      @include = []
      @exclude = []
      @options = {}
    end

    def within(*selectors)
      @include.concat(selectors.flatten)
      self
    end

    def excluding(*selectors)
      @exclude.concat(selectors.flatten)
      self
    end

    def skipping(*rules)
      rules.flatten.each { (@options[:rules] ||= {})[it] = { enabled: false } }
      self
    end

    def checking_only(*rules)
      @options[:runOnly] = { type: 'rule', values: rules.flatten }
      self
    end

    def according_to(*tags)
      @options[:runOnly] = { type: 'tag', values: tags.flatten }
      self
    end

    def matches?(page)
      @violations = audit(page).fetch('violations')
      @violations.empty?
    end

    def description
      'be axe clean'
    end

    def failure_message
      "Found #{@violations.size} accessibility violation(s):\n\n#{@violations.map { format_violation(it) }.join("\n")}"
    end

    def failure_message_when_negated
      'Expected accessibility violations, but the page is axe clean'
    end

    private

    def audit(page)
      page.driver.with_playwright_page do |playwright_page|
        source = AXE_SOURCE_PATH.read
        playwright_page.frames.each do |frame|
          frame.evaluate(source) unless frame.evaluate('typeof window.axe === "object"')
        end
        playwright_page.evaluate(RUN_SCRIPT, arg: { context:, options: @options })
      end
    end

    def context
      return nil if @include.empty? && @exclude.empty?

      { include: @include.map { [it] }, exclude: @exclude.map { [it] } }.reject { |_, v| v.empty? }
    end

    def format_violation(violation)
      nodes = violation['nodes'].map do |node|
        "    #{node['target'].join(', ')}\n      #{node['failureSummary']&.gsub("\n", "\n      ")}"
      end
      <<~MESSAGE.chomp
        #{violation['id']} (#{violation['impact']}): #{violation['help']}
          #{violation['helpUrl']}
        #{nodes.join("\n")}
      MESSAGE
    end
  end

  module Matchers
    def be_axe_clean
      BeAxeClean.new
    end
  end
end

RSpec.configure do |config|
  config.include AxePlaywright::Matchers, type: :system, js: true
end
