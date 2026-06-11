# frozen_string_literal: true

module LockableConcern
  extend ActiveSupport::Concern

  def lock_action(key)
    lock = Kredis.flag(key)
    # Atomic acquire (SET NX): only the request that actually sets the flag
    # enters the protected section, so concurrent requests cannot both pass.
    head :locked and return unless lock.mark(expires_in: 10.seconds, force: false)

    begin
      yield
    ensure
      lock.remove
    end
  end
end
