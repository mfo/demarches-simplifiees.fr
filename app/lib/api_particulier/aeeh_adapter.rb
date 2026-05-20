# frozen_string_literal: true

class APIParticulier::AeehAdapter < APIParticulier::API
  RESSOURCE = "v3/dss/allocation_enfant_handicape/identite"
  SCHEMA = "app/schemas/aeeh.json"
end
