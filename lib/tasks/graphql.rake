# frozen_string_literal: true

require "graphql/rake_task"
# The dump documents the whole schema, not what a restricted token can see.
GraphQL::RakeTask.new(schema_name: "API::V2::Schema", directory: 'app/graphql', load_context: ->(_task) { { internal_use: true } })
