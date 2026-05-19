# frozen_string_literal: true

class LogicSerializer
  def self.load(logic)
    if logic.present?
      Logic.from_h(logic)
    end
  end

  def self.dump(logic)
    logic.presence&.to_h
  end
end
