# frozen_string_literal: true

module LLM
  class CleanerImprover < BaseImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('cleaner'),
        description: 'Propose la suppression d\'un champ redondant',
        parameters: {
          type: 'object',
          properties: {
            destroy: {
              type: 'object',
              description: 'Suppression d\'un champ devenu redondant ou demandant une information déjà remontée via le champ Adresse, SIRET, …',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant du champ à supprimer.' },
              },
              required: %w[stable_id],
            },
            justification: { type: 'string' },
          },
          additionalProperties: false,
        },
      },
    }.freeze

    def system_prompt(procedure)
      <<~TXT
        Tu es un assistant chargé d'identifier les champs redondants d'un formulaire administratif français.

        Principe "Dites-le nous une fois" (DLNUF) : l'administration ne doit pas redemander des informations déjà collectées soit à l'entrée du formulaire, soit par un champ qui collecte des informations complémentaires.

        MÉTHODOLOGIE OBLIGATOIRE EN 2 PHASES :

        PHASE 1 OBLIGATOIRE - AUDIT (mental, pas de tool call) :
        Pour chaque champ du schéma :
        1. Analyse tous les autres champs du formulaire
        2. Vérifie si un autre champ fournit déjà l'information demandée (que ce soit un champ spécialisé comme SIRET/address ou un simple doublon)
        3. Vérifie le contexte : même section parente directe (header_section) ? même entité ?
        Si TOUTES les conditions sont OK → Marque-le mentalement pour suppression

        PHASE 2 - SUPPRESSION (avec tool calls) :
        Pour CHAQUE champ marqué en Phase 1, génère UN tool call avec l'outil #{TOOL_DEFINITION.dig(:function, :name)}.
        Continue jusqu'à avoir traité TOUS les champs marqués.

        PÉRIMÈTRE D'ACTION :
        - Tu proposes : suppression de champs redondants (destroy)
        - Tu ne touches JAMAIS à : libellé, description, position, type, mandatory, display_condition
        - Tu analyses : type du champ, libellé, description, position, section parente directe (header_section)
        - Le système filtrera automatiquement tes propositions pour éviter de supprimer des champs utilisés comme sources de conditions d'affichage
      TXT
    end

    def rules_prompt
      <<~TXT
        Applique ces règles PAR ORDRE DE PRIORITÉ.

        ═══════════════════════════════════════════════════════════════
        PRIORITÉ 1 : CONTRAINTES TECHNIQUES (bloquant si non respecté)
        ═══════════════════════════════════════════════════════════════

        1.1. Contexte de section
            - Vérifier que les champs sont dans le même contexte (même section parente directe)
            - Des sections différentes = des contextes/entités différents
            - Une section est définie par un champ header_section
              KO Section "Identité du demandeur" → [Adresse de résidence]
                  Section "Lieu de naissance" → [Commune de naissance]
                  + Champ "Adresse" fournit une commune
                  → NE PAS supprimer "Commune de naissance" (contextes différents : résidence ≠ naissance)
              OK Section "Informations sur l'entreprise" → [SIRET, Raison sociale, Adresse siège]
                  → Supprimer "Raison sociale" et "Adresse siège" (même section = même contexte)

        >> Si cette contrainte PRIORITÉ 1 ne peut être respectée : ABANDONNE ce champ.

        ═══════════════════════════════════════════════════════════════
        PRIORITÉ 2 : COHÉRENCE SÉMANTIQUE (éviter les incohérences)
        ═══════════════════════════════════════════════════════════════

        2.1. Même sujet/entité
            - Les champs doivent concerner exactement la même chose
            - Vérifier le libellé ET la description pour comprendre le contexte réel
              KO "Adresse de résidence" vs "Commune de naissance" (résidence ≠ naissance)
              KO "Adresse du siège social" vs "Adresse de correspondance" (siège ≠ correspondance)
              OK "Adresse" fournit "Commune" et champ "Commune" sans précision (même entité)


        ═══════════════════════════════════════════════════════════════
        TYPES DE CHAMPS SPÉCIALISÉS (référence)
        ═══════════════════════════════════════════════════════════════

        Localisation (avec auto-complétion et données enrichies) :
        - address : Adresse postale complète avec autocomplete. Fournit : commune, code postal, département, région, pays, code INSEE de la commune.
        - communes : Sélection d'une commune française. Fournit : nom, code postal, département, code INSEE

        Identification d'entités :
        - siret : Numéro SIRET d'une entreprise. Fournit automatiquement et exclusivement : raison sociale, SIREN, nom commercial, forme juridique, code et libellé NAF, adresse normalisée de l'établissement, adresse normalisée du siège social, N° TVA intracommunautaire, capital social, code effectif, date de création, état administratif.
        - rna : Répertoire National des Associations. Fournit : nom de l'association, titre et objet de l'association, adresse normalisée, état administratif
        - rnf : Répertoire National des Fondations. Fournit : nom, adresse normalisée, état administratif
        - annuaire_education : Identifiant d'un établissement scolaire. Fournit : nom de l'établissement, adresse normalisée, académie, nature de l'établissement, téléphone, email, site internet.

        Une "adresse normalisée" fournit ces informations:
        - numéro, nom de la voie
        - code postal
        - nom de la commune et son code INSEE
        - département

        ═══════════════════════════════════════════════════════════════
        EXEMPLES DÉTAILLÉS
        ═══════════════════════════════════════════════════════════════

        **Exemple 1 : Regroupement valide (ACCEPTÉ)**

        Schéma initial :
        [
          { stable_id: 10, libelle: "Informations entreprise", position: 0, type: "header_section" },
          { stable_id: 20, libelle: "SIRET", position: 1, type: "siret" },
          { stable_id: 30, libelle: "Raison sociale", position: 2, type: "text" },
          { stable_id: 40, libelle: "Adresse du siège social", position: 3, type: "text" }
        ]

        Analyse :
        - Le SIRET (position 1) fournit automatiquement raison sociale ET adresse du siège
        - Les champs Raison sociale et Adresse sont dans la même section "Informations entreprise"
        - Même contexte (l'entreprise), pas de nuance (pas "adresse de correspondance")
        - DÉCISION : Supprimer les champs 30 et 40 (redondance avérée)

        Tool calls corrects :
        {
          "destroy": { "stable_id": 30 },
          "justification": "Le champ SIRET fournit automatiquement la raison sociale."
        }
        {
          "destroy": { "stable_id": 40 },
          "justification": "Le champ SIRET fournit automatiquement l'adresse du siège social."
        }

        **Exemple 2 : Contexte de section différent (REJETÉ)**

        Schéma initial :
        [
          { stable_id: 5, libelle: "Votre identité", position: 0, type: "header_section" },
          { stable_id: 10, libelle: "Adresse de résidence", position: 1, type: "address" },
          { stable_id: 20, libelle: "Lieu de naissance", position: 2, type: "header_section" },
          { stable_id: 30, libelle: "Commune de naissance", position: 3, type: "communes" }
        ]

        Analyse :
        - L'adresse de résidence (position 1) fournit la commune de résidence
        - Le champ "Commune de naissance" (position 3) semble similaire techniquement
        - MAIS contextes différents : section "Votre identité" (résidence actuelle) ≠ section "Lieu de naissance" (passé)
        - Les sections indiquent clairement cette distinction
        - DÉCISION : NE PAS supprimer (violation PRIORITÉ 1.1 : contexte de section différent)

        ═══════════════════════════════════════════════════════════════
        OUTIL À UTILISER
        ═══════════════════════════════════════════════════════════════

        Utilise l'outil #{TOOL_DEFINITION.dig(:function, :name)} pour chaque proposition (un appel par suppression).
        Ne réponds rien s'il n'y a aucun champ redondant.

        >> RAPPEL CRITIQUE : Il vaut mieux ne faire AUCUNE proposition que de proposer quelque chose violant PRIORITÉ 1.
      TXT
    end

    def build_item(args, tdc_index: {})
      build_destroy_item(args, tdc_index:) if args['destroy']
    end

    private

    def build_destroy_item(args, tdc_index:)
      data = args['destroy']
      stable_id = data.is_a?(Hash) ? data['stable_id'] : data

      return if stable_id.nil?
      return if used_as_condition_source?(stable_id, tdc_index)

      {
        op_kind: 'destroy',
        stable_id:,
        payload: { 'stable_id' => stable_id },
        verify_status: 'pending',
        justification: args['justification'].presence,
      }
    end

    def used_as_condition_source?(stable_id, tdc_index)
      tdc_index.values.any? do |tdc|
        tdc.condition&.sources&.include?(stable_id)
      end
    end
  end
end
