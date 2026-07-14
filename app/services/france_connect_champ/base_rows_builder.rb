# frozen_string_literal: true

module FranceConnectChamp
  class BaseRowsBuilder
    include ActionView::Helpers::NumberHelper

    def build(_data)
      raise NotImplementedError
    end
  end
end
