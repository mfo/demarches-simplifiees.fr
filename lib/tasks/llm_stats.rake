# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

FEATURE_LAUNCH = Date.new(2026, 4, 1)
RULES = %w[improve_label improve_types improve_structure cleaner].freeze
STATES = %w[publiee brouillon close depubliee].freeze
PROCEDURE_JOIN = { llm_rule_suggestion: { procedure_revision: :procedure } }.freeze

namespace :llm do
  desc "Reporting Simpliscore : impact global (stock) + pilotage (flux 3 mois)"
  task stats: :environment do
    llm_stats_report
  end
end

def llm_stats_report
  today = Date.current
  months = rolling_months(today, 3)

  puts "=== Simpliscore — Reporting #{today.strftime('%d/%m/%Y')} ===\n\n"

  # =============================================
  # PARTIE 1 — IMPACT GLOBAL (STOCK)
  # =============================================
  stock = snapshot_stock(today)
  beta = snapshot_beta

  puts "## 1. Impact global (depuis le lancement)\n\n"

  puts "| Métrique | Total | dont beta (avant avril) |"
  puts "|---|---|---|"
  puts "| Démarches améliorées | #{fmt(stock[:procedures])} | #{fmt(beta[:procedures])} |"
  puts "| Suggestions acceptées | #{fmt(stock[:accepted])} | #{fmt(beta[:accepted])} |"
  puts "| Taux d'acceptation global | #{format("%.1f", stock[:acceptance_rate])}% | #{format("%.1f", beta[:acceptance_rate])}% |"
  puts "| Mises à jour | #{fmt(stock[:by_op]['update'] || 0)} | #{fmt(beta[:by_op]['update'] || 0)} |"
  puts "| Ajouts de sections | #{fmt(stock[:by_op]['add'] || 0)} | #{fmt(beta[:by_op]['add'] || 0)} |"
  puts "| Suppressions | #{fmt(stock[:by_op]['destroy'] || 0)} | #{fmt(beta[:by_op]['destroy'] || 0)} |"

  puts "\n**Par état de démarche :**\n\n"
  puts "| État | Démarches | Acceptations | Taux |"
  puts "|---|---|---|---|"
  STATES.each do |state|
    procs = stock[:procedures_by_state][state] || 0
    acc = stock[:accepted_by_state][state] || 0
    items = stock[:items_by_state][state] || 0
    rate = items > 0 ? (acc.to_f / items * 100).round(1) : 0
    puts "| #{state} | #{fmt(procs)} | #{fmt(acc)} | #{rate}% |"
  end

  puts "\n**Par règle :**\n\n"
  puts "| Règle | Acceptées | Suggestions | Taux |"
  puts "|---|---|---|---|"
  RULES.each do |rule|
    acc = stock[:by_rule][rule] || 0
    items = stock[:items_by_rule][rule] || 0
    rate = items > 0 ? (acc.to_f / items * 100).round(1) : 0
    puts "| #{rule.tr('_', ' ')} | #{fmt(acc)} | #{fmt(items)} | #{rate}% |"
  end

  # =============================================
  # PARTIE 2 — PILOTAGE (FLUX 3 MOIS GLISSANTS)
  # =============================================
  fluxes = months.map { |range| [range, snapshot_flux(range)] }

  puts "\n\n## 2. Pilotage (flux mensuel)\n\n"

  headers = ["KPI"] + months.map { |r| "#{r.first.strftime('%d/%m')}→#{r.max.strftime('%d/%m')}" } + ["Tendance"]

  puts table(headers, [
    flux_row("Suggestions générées", fluxes.map { it[1][:items] }),
    flux_row("Décisions prises", fluxes.map { it[1][:decided] }),
    flux_row("Acceptées", fluxes.map { it[1][:accepted] }),
    flux_row("Taux d'acceptation", fluxes.map { it[1][:acceptance_rate] }, suffix: "%"),
    flux_row("Démarches touchées", fluxes.map { it[1][:procedures] }),
  ])

  puts "\n**Flux par règle (acceptations) :**\n\n"
  rule_rows = RULES.map do |rule|
    flux_row(rule.tr('_', ' '), fluxes.map { it[1][:by_rule][rule] || 0 })
  end
  puts table(headers, rule_rows)

  puts "\n**Flux par règle (taux d'acceptation) :**\n\n"
  rule_rate_rows = RULES.map do |rule|
    flux_row(rule.tr('_', ' '), fluxes.map do |_r, f|
      items = f[:items_by_rule][rule] || 0
      acc = f[:by_rule][rule] || 0
      items > 0 ? (acc.to_f / items * 100).round(1) : 0
    end, suffix: "%")
  end
  puts table(headers, rule_rate_rows)

  puts "\n**Flux par état de démarche (acceptations) :**\n\n"
  state_rows = STATES.map do |state|
    flux_row(state, fluxes.map { it[1][:accepted_by_state][state] || 0 })
  end
  puts table(headers, state_rows)

  # =============================================
  # PARTIE 3 — ANALYSE LLM
  # =============================================
  puts "\n\n## 3. Analyse LLM\n\n"

  stats_for_llm = build_llm_context(stock, beta, fluxes, months)

  messages = [
    { role: 'system', content: llm_system_prompt },
    { role: 'user', content: stats_for_llm },
  ]

  begin
    prev_level = Langchain.logger.level
    Langchain.logger.level = Logger::FATAL
    raw_response = LLM::OpenAIClient.instance.chat({
      messages:,
      temperature: 0.3,
      model: ENV['LLM_MODEL_NAME'],
    })
    raw = raw_response.respond_to?(:raw_response) ? raw_response.raw_response : raw_response
    content = raw.dig('choices', 0, 'message', 'content')
    puts content || "Pas de réponse du LLM"
  rescue => e
    puts "Erreur LLM (#{e.class}): #{e.message}"
  ensure
    Langchain.logger.level = prev_level
  end

  puts "\n=== Fin ==="
end

# --- Données ---

def rolling_months(today, count)
  Array.new(count) do |i|
    period_end = today - (count - 1 - i).months
    period_start = period_end - 1.month
    period_start = [period_start, FEATURE_LAUNCH].max
    period_start...[period_end, today].min
  end
end

def snapshot_beta
  items = LLMRuleSuggestionItem.joins(:llm_rule_suggestion)
    .where(llm_rule_suggestions: { created_at: ...FEATURE_LAUNCH })

  accepted_items = items.where(verify_status: "accepted", applied_at: ...FEATURE_LAUNCH)
  items_count = items.count
  accepted_count = accepted_items.count

  {
    accepted: accepted_count,
    acceptance_rate: items_count > 0 ? (accepted_count.to_f / items_count * 100).round(1) : 0,
    procedures: accepted_items.joins(PROCEDURE_JOIN).distinct.count("procedures.id"),
    by_op: accepted_items.group(:op_kind).count,
  }
end

def snapshot_stock(cutoff)
  items = LLMRuleSuggestionItem.joins(:llm_rule_suggestion)

  accepted_items = items.where(verify_status: "accepted", applied_at: ...cutoff)
  items_count = items.count
  accepted_count = accepted_items.count

  {
    accepted: accepted_count,
    acceptance_rate: items_count > 0 ? (accepted_count.to_f / items_count * 100).round(1) : 0,
    procedures: accepted_items.joins(PROCEDURE_JOIN).distinct.count("procedures.id"),
    by_op: accepted_items.group(:op_kind).count,
    by_rule: accepted_items.joins(:llm_rule_suggestion).group("llm_rule_suggestions.rule").count,
    items_by_rule: items.joins(:llm_rule_suggestion).group("llm_rule_suggestions.rule").count,
    procedures_by_state: accepted_items.joins(PROCEDURE_JOIN).distinct("procedures.id").group("procedures.aasm_state").count("procedures.id"),
    accepted_by_state: accepted_items.joins(PROCEDURE_JOIN).group("procedures.aasm_state").count,
    items_by_state: items.joins(PROCEDURE_JOIN).group("procedures.aasm_state").count,
  }
end

def snapshot_flux(range)
  items_created = LLMRuleSuggestionItem.joins(:llm_rule_suggestion)
    .where(llm_rule_suggestions: { created_at: range })

  accepted = LLMRuleSuggestionItem.where(verify_status: "accepted", applied_at: range)
  skipped = LLMRuleSuggestionItem.where(verify_status: "skipped", updated_at: range)

  accepted_count = accepted.count
  skipped_count = skipped.count
  decided = accepted_count + skipped_count

  {
    items: items_created.count,
    accepted: accepted_count,
    skipped: skipped_count,
    decided: decided,
    acceptance_rate: decided > 0 ? (accepted_count.to_f / decided * 100).round(1) : 0,
    procedures: accepted.joins(PROCEDURE_JOIN).distinct.count("procedures.id"),
    by_rule: accepted.joins(:llm_rule_suggestion).group("llm_rule_suggestions.rule").count,
    items_by_rule: items_created.joins(:llm_rule_suggestion).group("llm_rule_suggestions.rule").count,
    accepted_by_state: accepted.joins(PROCEDURE_JOIN).group("procedures.aasm_state").count,
  }
end

# --- Formatage ---

def fmt(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1 ').reverse
end

def trend(values)
  return "—" if values.size < 2 || values.all?(&:zero?)

  recent = values.last(2)
  return "→" if recent[0] == 0 && recent[1] == 0

  delta = recent[1] - recent[0]
  pct = recent[0] != 0 ? (delta.to_f / recent[0].abs * 100) : (delta > 0 ? 100 : -100)

  if pct > 15 then "↑"
  elsif pct > 5 then "↗"
  elsif pct > -5 then "→"
  elsif pct > -15 then "↘"
  else "↓"
  end
end

def flux_row(label, values, suffix: nil)
  formatted = values.map { |v| suffix ? "#{format("%.1f", v)}#{suffix}" : fmt(v) }
  [label] + formatted + [trend(values)]
end

def table(headers, rows)
  cells = headers.map(&:to_s)
  lines = []
  lines << "| #{cells.join(' | ')} |"
  lines << "|#{'---|' * cells.size}"
  rows.each { |row| lines << "| #{row.join(' | ')} |" }
  lines.join("\n")
end

# --- LLM ---

def build_llm_context(stock, beta, fluxes, months)
  <<~MD
    ## Impact global (stock, beta + post-lancement)
    Démarches améliorées : #{fmt(stock[:procedures])} (dont #{fmt(beta[:procedures])} en beta avant avril 2026)
    Suggestions acceptées : #{fmt(stock[:accepted])} (dont #{fmt(beta[:accepted])} en beta) — taux global : #{format("%.1f", stock[:acceptance_rate])}%
    Par op : #{stock[:by_op].map { "#{it.first}=#{it.last}" }.join(", ")}
    Par règle (acceptées/total → taux) :
    #{RULES.map do |r|
      acc = stock[:by_rule][r] || 0; tot = stock[:items_by_rule][r] || 0
      rate = tot > 0 ? (acc.to_f / tot * 100).round(1) : 0
      "  #{r} : #{acc}/#{tot} (#{rate}%)"
    end.join("\n")}
    Par état (démarches améliorées) : #{STATES.map { |s| "#{s}=#{stock[:procedures_by_state][s] || 0}" }.join(", ")}

    ## Flux (3 périodes glissantes de ~30 jours)
    #{fluxes.map do |range, f|
      days = (range.max - range.first).to_i
      <<~MONTH
        #{range.first.strftime('%d/%m/%Y')} → #{range.max.strftime('%d/%m/%Y')} (#{days} jours) :
          Suggestions générées : #{f[:items]}
          Décisions : #{f[:decided]} (#{f[:accepted]} acceptées, #{f[:skipped]} ignorées)
          Taux d'acceptation : #{format("%.1f", f[:acceptance_rate])}%
          Démarches touchées : #{f[:procedures]}
          Par règle : #{RULES.map { |r| "#{r}=#{f[:by_rule][r] || 0}" }.join(", ")}
          Par état : #{STATES.map { |s| "#{s}=#{f[:accepted_by_state][s] || 0}" }.join(", ")}
      MONTH
    end.join("\n")}
  MD
end

def llm_system_prompt
  <<~PROMPT
    Tu es un analyste data au sein d'une équipe produit d'un service public numérique français
    (demarches-simplifiees.fr). Tu analyses les données d'une feature interne appelée "Simpliscore"
    lancée en avril 2026, qui utilise l'IA pour suggérer des améliorations aux formulaires administratifs.

    Contexte métier :
    - Les administrateurs de démarches créent des formulaires pour les usagers (citoyens, entreprises)
    - Simpliscore génère des suggestions d'amélioration : meilleurs libellés, ajout de sections, correction de types de champs, nettoyage
    - Les admins peuvent accepter ou ignorer chaque suggestion
    - Les 4 règles s'exécutent successivement dans un tunnel, dans cet ordre :
      1. improve_label (libellés) — appliquée à tous les champs, donc volume le plus élevé
      2. improve_structure (sections) — s'exécute sur le formulaire déjà amélioré par improve_label
      3. improve_types (types de champs) — s'exécute après les deux précédentes
      4. cleaner (suppression de champs inutiles) — dernière étape, volume le plus faible
      Le volume décroissant par règle est structurel : chaque règle s'applique sur un périmètre de plus en plus réduit

    États des démarches :
    - publiee : en production, visible par les usagers (impact réel sur les citoyens)
    - brouillon : en construction (l'admin prépare son formulaire)
    - close/depubliee : fermées, mais peuvent être clonées pour créer de nouvelles démarches

    Historique :
    - Avant avril 2026 (beta), les suggestions étaient auto-générées en batch nocturne sur un large
      volume de démarches, sans initiative de l'administrateur. Ce mécanisme a été retiré (erreurs 429).
    - Depuis avril 2026 (lancement), les suggestions sont générées uniquement à l'initiative de l'admin.
    - Le stock inclut toutes les suggestions (beta + post-lancement). Les suggestions beta non traitées
      gonflent le dénominateur stock, ce qui explique l'écart entre le taux stock (~22%) et le taux flux (~47%).

    Les données sont présentées en deux vues :
    - Stock : impact cumulé depuis le lancement (pour mesurer l'impact global)
      Le taux d'acceptation stock = acceptées / total des suggestions générées
    - Flux : 3 périodes glissantes de ~30 jours (pour détecter les tendances)
      Le taux d'acceptation flux = acceptées / décisions prises (acceptées + ignorées)
      Ces deux taux ont des dénominateurs différents — ne pas les comparer directement

    Attention aux pièges d'interprétation :
    - L'écart entre taux stock (~22%) et taux flux (~47%) est expliqué par le batch beta (voir Historique).
      Ne le signale pas comme une anomalie ou une question ouverte.
    - La première période peut être plus courte que 30 jours (capée au lancement en avril 2026).
      La durée en jours est indiquée pour chaque période. Ne compare les volumes absolus
      qu'entre périodes de même durée. Si une période est plus courte, normalise mentalement.
    - Le volume décroissant par règle n'est PAS un signal d'adoption : c'est structurel (tunnel séquentiel).
      Ne le signale pas comme un point d'attention.
    - Les démarches close/depubliée peuvent être clonées — des améliorations sur ces démarches
      ont un impact indirect sur les futures démarches créées par clonage.

    Ta mission : interpréter les données, pas faire des recommandations.
    Produis une synthèse structurée en markdown :
    1. **Lecture des données** — que disent les chiffres ? Quelles tendances, quelles ruptures, quels signaux faibles ?
    2. **Questions ouvertes** — que faudrait-il creuser pour mieux comprendre ? Quelles hypothèses les données ne permettent pas de trancher ?

    Règles :
    - Sois factuel et nuancé. Cite les chiffres.
    - Ne fais pas de recommandations d'action ni de suggestions produit — ce n'est pas ton rôle.
    - Si une donnée est ambiguë ou insuffisante pour conclure, dis-le.
    - Compare les périodes flux uniquement entre elles, pas avec le stock.
    - Écris en français, 300 mots max.
  PROMPT
end
