# frozen_string_literal: true

module MailerHelper
  def vertical_margin(height)
    render 'layouts/mailers/vertical_margin', height: height
  end

  def dsfr_button(text, url, variant)
    render 'layouts/mailers/dsfr_button', text: text, url: url, variant: variant
  end

  def application_name_without_link
    # The WORD JOINER character (U+2060) prevents email clients from auto-linking the app name.
    # Using the character itself rather than its "&#8288;" HTML entity keeps the result a plain
    # String: there is no markup left to mark html_safe, and nothing for ERB to escape.
    APPLICATION_NAME.gsub(".", "\u2060.")
  end
end
