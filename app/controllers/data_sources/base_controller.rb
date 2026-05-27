# frozen_string_literal: true

class DataSources::BaseController < ApplicationController
  before_action :authenticate_data_source_user!

  private

  def authenticate_data_source_user!
    authenticate_logged_user!
  end
end
