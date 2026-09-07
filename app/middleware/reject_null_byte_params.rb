# frozen_string_literal: true

# PostgreSQL refuses strings containing a null byte, and so does bcrypt, so a
# request carrying one in a parameter can only end in a 500 once the value
# reaches them. Nothing legitimate sends null bytes: answer 400 up front, the
# way Rails already does for parameters with an invalid encoding.
class RejectNullByteParams
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    if null_byte?(request.query_parameters) || null_byte?(request.request_parameters)
      raise ActionController::BadRequest, "Invalid request parameters: null byte"
    end

    @app.call(env)
  end

  private

  def null_byte?(value)
    case value
    when String then value.include?("\0")
    when Array then value.any? { null_byte?(it) }
    when Hash then value.any? { |key, item| null_byte?(key) || null_byte?(item) }
    else false
    end
  end
end
