# frozen_string_literal: true

# Zones (ministères) mirror config/zones.yml — the same source of truth
# Maintenance::UpdateZonesTask syncs in production.
ministeres = Psych.safe_load(Rails.root.join("config/zones.yml").read).fetch("ministeres")

ministeres.each do |ministere|
  acronym = ministere.keys.first
  zone = zones.create(acronym:, tchap_hs: ministere["tchap_hs"] || [])
  ministere["labels"].each do |label|
    designated_on = label.keys.first
    zone.labels.create!(designated_on:, name: label.fetch(designated_on))
  end
end

# The demo procedures publish under DINUM's ministry.
zones.label default: Zone.find_by!(acronym: "MTFP")
