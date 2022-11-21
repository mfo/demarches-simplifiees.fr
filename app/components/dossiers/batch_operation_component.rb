class Dossiers::BatchOperationComponent < ApplicationComponent
  attr_reader :form, :statut
  def initialize(statut:, form:)
    @statut = statut
    @form = form
  end

  def render_button?
    @statut == 'traites'
  end

  def available_operations
    options = [t('.prompt')]
    case @statut
    when 'traites' then
      options.push [t(".operations.archiver"), BatchOperation.operations.fetch(:archiver)]
    else
    end

    options
  end
end
