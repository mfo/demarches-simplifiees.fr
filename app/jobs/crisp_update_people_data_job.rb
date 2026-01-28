# frozen_string_literal: true

class CrispUpdatePeopleDataJob < ApplicationJob
  include Dry::Monads[:result]

  discard_on ActiveRecord::RecordNotFound

  queue_as :default

  def perform(session_id, email)
    meta = fetch_conversation_meta(session_id)
    email ||= meta[:email]
    user = User.find_by!(email:)

    update_people_data(user)
  end

  private

  def fetch_conversation_meta(session_id)
    result = Crisp::APIService.new.get_conversation_meta(session_id:)
    case result
    in Success(data:)
      { email: data[:email], segments: data[:segments] || [] }
    in Failure(reason:)
      fail reason
    end
  end

  def update_people_data(user)
    user_data = Crisp::UserDataBuilder.new(user).build_data
    result = Crisp::APIService.new.update_people_data(email: user.email, body: { data: user_data })

    case result
    in Success
    # NOOP
    in Failure(reason:)
      fail reason
    end
  end
end
