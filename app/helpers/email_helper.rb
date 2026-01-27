# frozen_string_literal: true

module EmailHelper
  def status_color_code(status)
    if status.in?(['delivered', 'sent'])
      'email-sent'
    elsif status.in?(['failed', 'blocked']) || status.include?('hardBounces')
      'email-blocked'
    else
      ''
    end
  end
end
