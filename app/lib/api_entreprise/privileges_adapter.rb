# frozen_string_literal: true

class APIEntreprise::PrivilegesAdapter < APIEntreprise::Adapter
  def initialize(token)
    @token = token
  end

  def valid?
    get_resource.success?
  end

  private

  def get_resource
    api.tap do
      _1.token = @token
    end.privileges
  end
end
