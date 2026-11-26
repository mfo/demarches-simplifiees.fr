# frozen_string_literal: true

class Conditions::ConditionsErrorsComponent < ApplicationComponent
  def initialize(condition:, source_tdcs:)
    @condition, @source_tdcs = condition, source_tdcs
  end

  private

  def errors = to_html_list(messages)

  def messages = @messages ||= Logic::ErrorMessages.new(@condition, @source_tdcs).to_a

  def to_html_list(messages)
    messages
      .map { |message| tag.li(message) }
      .then { |lis| tag.ul(lis.reduce(&:+)) }
  end

  def render? = messages.present?
end
