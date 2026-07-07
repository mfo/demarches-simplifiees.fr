# frozen_string_literal: true

module Manager
  class TopActivityProceduresController < Manager::ApplicationController
    def index
      raw_resources = TopActivityProcedure.all
      resources = Kaminari.paginate_array(raw_resources).page(params[:_page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard)

      render locals: {
        resources: resources,
        page: page,
        show_search_bar: false,
        search_term: nil,
        filters: {},
      }
    end
  end
end
