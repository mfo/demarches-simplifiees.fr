# frozen_string_literal: true

# GroupeGestionnaire is the only model using ancestry, so the gem and its
# configuration belong to this engine.
Ancestry.default_ancestry_format = :materialized_path2
