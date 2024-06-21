class EmailChecker
  # Extracted 100 most used domain on our users table [june 2024]
  # + all .gouv.fr domain on our users table
  # + all .ac-xxx on our users table
  KNOWN_DOMAINS = [
    'gmail.com',
    'hotmail.fr',
    'orange.fr',
    'yahoo.fr',
    'hotmail.com',
    'outlook.fr',
    'wanadoo.fr',
    'free.fr',
    'yahoo.com',
    'icloud.com',
    'laposte.net',
    'live.fr',
    'sfr.fr',
    'outlook.com',
    'neuf.fr',
    'aol.com',
    'bbox.fr',
    'msn.com',
    'me.com',
    'gmx.fr',
    'protonmail.com',
    'club-internet.fr',
    'live.com',
    'ymail.com',
    'ars.sante.fr',
    'mail.ru',
    'cegetel.net',
    'numericable.fr',
    'aliceadsl.fr',
    'comcast.net',
    'assurance-maladie.fr',
    'mac.com',
    'naver.com',
    'airbus.com',
    'justice.fr',
    'pole-emploi.fr',
    'educagri.fr',
    'aphp.fr',
    'netcourrier.com',
    'dbmail.com',
    'aol.fr',
    'qq.com',
    'hotmail.co.uk',
    'yahoo.co.uk',
    'proxima-mail.fr',
    'yahoo.com.br',
    'sciencespo.fr',
    'gmx.com',
    'etu.univ-st-etienne.fr',
    'yahoo.ca',
    '163.com',
    'francetravail.fr',
    'mail.pf',
    'nantesmetropole.fr',
    'hotmail.it',
    'sbcglobal.net',
    'noos.fr',
    'ird.fr',
    'safrangroup.com',
    'croix-rouge.fr',
    'eiffage.com',
    'veolia.com',
    'notaires.fr',
    'nordnet.fr',
    'videotron.ca',
    'paris.fr',
    'lilo.org',
    'mfr.asso.fr',
    'yopmail.com',
    'ukr.net',
    'onf.fr',
    'stellantis.com',
    '9online.fr',
    'atmp50.fr',
    'engie.com',
    'libertysurf.fr',
    'mailo.com',
    'auchan.fr',
    'verizon.net',
    'rocketmail.com',
    'mpsa.com',
    'entrepreneur.fr',
    'googlemail.com',
    'arcelormittal.com',
    'groupe-sos.org',
    'proton.me',
    'att.net',
    'pm.me',
    'orange.com',
    'abv.bg',
    'yahoo.es',
    'creditmutuel.fr',
    'yandex.ru',
    'essec.edu',
    'urssaf.fr',
    'bpifrance.fr',
    'uol.com.br',
    'suez.com',
    'univ-st-etienne.fr',
    'korian.fr',
    'developpement-durable.gouv.fr',
    'modernisation.gouv.fr',
    'social.gouv.fr',
    'emploi.gouv.fr',
    'agriculture.gouv.fr',
    'intradef.gouv.fr',
    'interieur.gouv.fr',
    'oise.gouv.fr',
    'direccte.gouv.fr',
    'culture.gouv.fr',
    'pas-de-calais.gouv.fr',
    'finances.gouv.fr',
    'drieets.gouv.fr',
    'drjscs.gouv.fr',
    'sg.social.gouv.fr',
    'martinique.pref.gouv.fr',
    'beta.gouv.fr',
    'dieccte.gouv.fr',
    'cotes-darmor.gouv.fr',
    'vosges.gouv.fr',
    'developppement-durable.gouv.fr',
    'mayenne.gouv.fr',
    'aviation-civile.gouv.fr',
    'data.gouv.fr',
    'recherche.gouv.fr',
    'sante.gouv.fr',
    'paris-idf.gouv.fr',
    'guyane.gouv.fr',
    'douane.finances.gouv.fr',
    'cget.gouv.fr',
    'herault.gouv.fr',
    'loire-atlantique.gouv.fr',
    'manche.gouv.fr',
    'seine-maritime.gouv.fr',
    'dgccrf.finances.gouv.fr',
    'tarn-et-garonne.gouv.fr',
    'dila.gouv.fr',
    'diplomatie.gouv.fr',
    'haut-rhin.gouv.fr',
    'nord.gouv.fr',
    'bouches-du-rhone.gouv.fr',
    'alpes-de-haute-provence.gouv.fr',
    'hautes-alpes.gouv.fr',
    'alpes-maritimes.gouv.fr',
    'var.gouv.fr',
    'vaucluse.gouv.fr',
    'rhone.gouv.fr',
    'occitanie.gouv.fr',
    'ille-et-vilaine.gouv.fr',
    'finistere.gouv.fr',
    'aisne.gouv.fr',
    'indre.gouv.fr',
    'yvelines.gouv.fr',
    'bas-rhin.gouv.fr',
    'landes.gouv.fr',
    'haute-marne.gouv.fr',
    'correze.gouv.fr',
    'val-doise.gouv.fr',
    'seine-et-marne.gouv.fr',
    'essonne.gouv.fr',
    'calvados.gouv.fr',
    'charente-maritime.gouv.fr',
    'corse-du-sud.gouv.fr',
    'gironde.gouv.fr',
    'haute-corse.gouv.fr',
    'morbihan.gouv.fr',
    'pyrenees-atlantiques.gouv.fr',
    'pyrenees-orientales.gouv.fr',
    'somme.gouv.fr',
    'vendee.gouv.fr',
    'dgtresor.gouv.fr',
    'marne.gouv.fr',
    'auvergne-rhone-alpes.gouv.fr',
    'meurthe-et-moselle.gouv.fr',
    'pm.gouv.fr',
    'oncfs.gouv.fr',
    'orne.gouv.fr',
    'charente.gouv.fr',
    'travail.gouv.fr',
    'gard.gouv.fr',
    'maine-et-loire.gouv.fr',
    'moselle.gouv.fr',
    'outre-mer.gouv.fr',
    'jscs.gouv.fr',
    'haute-garonne.gouv.fr',
    'vienne.gouv.fr',
    'dordogne.gouv.fr',
    'eure.gouv.fr',
    'meuse.gouv.fr',
    'savoie.gouv.fr',
    'doubs.gouv.fr',
    'bfc.gouv.fr',
    'education.gouv.fr',
    'ariege.gouv.fr',
    'normandie.gouv.fr',
    'gendarmerie.interieur.gouv.fr',
    'ain.gouv.fr',
    'ardennes.gouv.fr',
    'drome.gouv.fr',
    'bretagne.gouv.fr',
    'paca.gouv.fr',
    'haute-saone.gouv.fr',
    'lot.gouv.fr',
    'dgfip.finances.gouv.fr',
    'aveyron.gouv.fr',
    'gers.gouv.fr',
    'tarn.gouv.fr',
    'aude.gouv.fr',
    'lozere.gouv.fr',
    'hautes-pyrenees.gouv.fr',
    'jeunesse-sports.gouv.fr',
    'alpes.maritimes.gouv.fr',
    'dreets.gouv.fr',
    'justice.gouv.fr',
    'sports.gouv.fr',
    'nouvelle-aquitaine.gouv.fr',
    'jura.gouv.fr',
    'haute-savoie.gouv.fr',
    'creuse.gouv.fr',
    'creps-poitiers.sports.gouv.fr',
    'equipement-agriculture.gouv.fr',
    'ira-metz.gouv.fr',
    'loire.gouv.fr',
    'defense.gouv.fr',
    'paris.gouv.fr',
    'ensm.sports.gouv.fr',
    'isere.gouv.fr',
    'haute-loire.gouv.fr',
    'cantal.gouv.fr',
    'lot-et-garonne.gouv.fr',
    'reunion.pref.gouv.fr',
    'loiret.gouv.fr',
    'indre-et-loire.gouv.fr',
    'eleve.ira-metz.gouv.fr',
    'deux-sevres.gouv.fr',
    'inao.gouv.fr',
    'franceconnect.gouv.fr',
    'essone.gouv.fr',
    'workinfrance.beta.gouv.fr',
    'seine-saint-denis.gouv.fr',
    'val-de-marne.gouv.fr',
    'morbihan.pref.gouv.fr',
    'externes.justice.gouv.fr',
    'haute-vienne.gouv.fr',
    'territoire-de-belfort.gouv.fr',
    'creps-reunion.sports.gouv.fr',
    'creps-centre.sports.gouv.fr',
    'creps-rhonealpes.sports.gouv.fr',
    'creps-montpellier.sports.gouv.fr',
    'nord.pref.gouv.fr',
    'charente-maritime.pref.gouv.fr',
    'cher.gouv.fr',
    'cote-dor.gouv.fr',
    'ssi.gouv.fr',
    'ira.gouv.fr',
    'pays-de-la-loire.gouv.fr',
    'loir-et-cher.gouv.fr',
    'saone-et-loire.gouv.fr',
    'enseignementsup.gouv.fr',
    'eure-et-loir.gouv.fr',
    'yonne.gouv.fr',
    'guadeloupe.pref.gouv.fr',
    'centre-val-de-loire.gouv.fr',
    'entreprise.api.gouv.fr',
    'grand-est.gouv.fr',
    'sarthe.gouv.fr',
    'sarthe.pref.gouv.fr',
    'puy-de-dome.gouv.fr',
    'externes.sante.gouv.fr',
    'allier.gouv.fr',
    'aube.gouv.fr',
    'nievre.gouv.fr',
    'ardeche.gouv.fr',
    'api.gouv.fr',
    'hauts-de-seine.gouv.fr',
    'hauts-de-france.gouv.fr',
    'temp-beta.gouv.fr',
    'def.gouv.fr',
    'particulier.api.gouv.fr',
    'ira-lille.gouv.fr',
    'haute-saone.pref.gouv.fr',
    'yvelines.pref.gouv.fr',
    'sgg.pm.gouv.fr',
    'anah.gouv.fr',
    'corse.gouv.fr',
    'mayenne.pref.gouv.fr',
    'cote-dor.pref.gouv.fr',
    'guyane.pref.gouv.fr',
    'ira-nantes.gouv.fr',
    'igas.gouv.fr',
    'tarn.pref.gouv.fr',
    'martinique.gouv.fr',
    'creps-paca.sports.gouv.fr',
    'ofb.gouv.fr',
    'loir-et-cher.pref.gouv.fr',
    'indre-et-loire.pref.gouv.fr',
    'polynesie-francaise.pref.gouv.fr',
    'scl.finances.gouv.fr',
    'numerique.gouv.fr',
    'cantal.pref.gouv.fr',
    'territoire-de-belfort.pref.gouv.fr',
    'creps-wattignies.sports.gouv.fr',
    'vienne.pref.gouv.fr',
    'ardennes.pref.gouv.fr',
    'creps-strasbourg.sports.gouv.fr',
    'creps-dijon.sports.gouv.fr',
    'ara.gouv.fr',
    'sgdsn.gouv.fr',
    'pays-de-la-loire.pref.gouv.fr',
    'anct.gouv.fr',
    'creps-pap.sports.gouv.fr',
    'sgae.gouv.fr',
    'esnm.sports.gouv.fr',
    'nouvelle-caledonie.gouv.fr',
    'deets.gouv.fr',
    'mayotte.gouv.fr',
    'creps-bordeaux.sports.gouv.fr',
    'civs.gouv.fr',
    'iga.interieur.gouv.fr',
    'cab.travail.gouv.fr',
    'ira-bastia.gouv.fr',
    'ira-lyon.gouv.fr',
    'creps-lorraine.sports.gouv.fr',
    'dihal.gouv.fr',
    'ofpra.gouv.fr',
    'mayotte.pref.gouv.fr',
    'strategie.gouv.fr',
    'territoires.gouv.fr',
    'dgcl.gouv.fr',
    'doubs.pref.gouv.fr',
    'service-civique.gouv.fr',
    'maine-et-loire.pref.gouv.fr',
    'envsn.sports.gouv.fr',
    'wallis-et-futuna.pref.gouv.fr',
    'gendarmerie.defense.gouv.fr',
    'anlci.gouv.fr',
    'cabinets.finances.gouv.fr',
    'seine-maritime.pref.gouv.fr',
    'promo46.ira-metz.gouv.fr',
    'aisne.pref.gouv.fr',
    'sportsdenature.gouv.fr',
    'loire-atlantique.pref.gouv.fr',
    'aude.pref.gouv.fr',
    'premier-ministre.gouv.fr',
    'igf.finances.gouv.fr',
    'eleves.ira-bastia.gouv.fr',
    'igesr.gouv.fr',
    'alpc.gouv.fr',
    'externes.emploi.gouv.fr',
    'prestataire.finances.gouv.fr',
    'gironde.pref.gouv.fr',
    'premar-atlantique.gouv.fr',
    'creps-toulouse.sports.gouv.fr',
    'guadeloupe.gouv.fr',
    'cybermalveillance.gouv.fr',
    'dicod.defense.gouv.fr',
    'creps-vichy.sports.gouv.fr',
    'aft.gouv.fr',
    'equipement.gouv.fr',
    'academie.defense.gouv.fr',
    'aube.pref.gouv.fr',
    'seine-et-marne.pref.gouv.fr',
    'pyrenees-orientales.pref.gouv.fr',
    'haute-garonne.pref.gouv.fr',
    'haut-rhin.pref.gouv.fr',
    'seine-saint-denis.pref.gouv.fr',
    'dcstep.gouv.fr',
    'promo47.ira-metz.gouv.fr',
    'trackdechets.beta.gouv.fr',
    'val-de-marne.pref.gouv.fr',
    'fabrique.social.gouv.fr',
    'agrasc.gouv.fr',
    'indre.pref.gouv.fr',
    'tarn-et-garonne.pref.gouv.fr',
    'corse.pref.gouv.fr',
    'bas-rhin.pref.gouv.fr',
    'inclusion.beta.gouv.fr',
    'hauts-de-seine.pref.gouv.fr',
    'loiret.pref.gouv.fr',
    'essonne.pref.gouv.fr',
    'territoires-industrie.gouv.fr',
    'spm975.gouv.fr',
    'saint-barth-saint-martin.gouv.fr',
    'judiciaire.interieur.gouv.fr',
    'mer.gouv.fr',
    'premar-manche.gouv.fr',
    'haute-normandie.pref.gouv.fr',
    'prestataire.modernisation.gouv.fr',
    'covoiturage.beta.gouv.fr',
    'promo48.ira-metz.gouv.fr',
    'france-services.gouv.fr',
    'ddets.gouv.fr',
    'afa.gouv.fr',
    'externes.social.gouv.fr',
    'vosges.pref.gouv.fr',
    'reunion.gouv.fr',
    'rhone.pref.gouv.fr',
    'alpes-maritimes.pref.gouv.fr',
    'gard.pref.gouv.fr',
    'oise.pref.gouv.fr',
    'creps-reims.sports.gouv.fr',
    'bouches-du-rhone.pref.gouv.fr',
    'esante.gouv.fr',
    'rhone-alpes.pref.gouv.fr',
    'finistere.pref.gouv.fr',
    'ops-bss.defense.gouv.fr',
    'orne.pref.gouv.fr',
    'transformation.gouv.fr',
    'cbcm.social.gouv.fr',
    'recosante.beta.gouv.fr',
    'pas-de-calais.pref.gouv.fr',
    'promo49.ira-metz.gouv.fr',
    'paca.pref.gouv.fr',
    'meurthe-et-moselle.pref.gouv.fr',
    'externes.sg.social.gouv.fr',
    'puy-de-dome.pref.gouv.fr',
    'academie.def.gouv.fr',
    'tarn.gouv.frd81intranet.ddcspp.tarn.gouv.fr',
    'agriculture-equipement.gouv.fr',
    'creps-idf.sports.gouv.fr',
    'eleve.ira-nantes.gouv.fr',
    'cohesion-territoires.gouv.fr',
    'ariege.pref.gouv.fr',
    'pyrenees-atlantiques.pref.gouv.fr',
    'hautes-pyrenees.pref.gouv.fr',
    'lot-et-garonne.pref.gouv.fr',
    'loire.pref.gouv.fr',
    'info-routiere.gouv.fr',
    'diges.gouv.fr',
    'insp.gouv.fr',
    'creps-pdl.sports.gouv.fr',
    'ddc.social.gouv.fr',
    'eleve.insp.gouv.fr',
    'val-doise.pref.gouv.fr',
    'montsaintmichel.gouv.fr',
    'st-cyr.terre-net.defense.gouv.fr',
    '.finances.gouv.fr',
    'logement.gouv.fr',
    'cotes-darmor.pref.gouv.fr',
    'marne.pref.gouv.fr',
    'herault.pref.gouv.fr',
    'viennne.gouv.fr',
    'landes.pref.gouv.fr',
    'moselle.pref.gouv.fr',
    'saone-et-loire.pref.gouv.fr',
    'bmpm.gouv.fr',
    'ecologie-territoires.gouv.fr',
    'nievre.pref.gouv.fr',
    'hautes-pyrénées.gouv.fr',
    'gic.gouv.fr',
    'industrie.gouv.fr',
    'lot.pref.gouv.fr',
    'plan.gouv.fr',
    'internet.gouv.fr',
    'mesads.beta.gouv.fr',
    'gers.pref.gouv.fr',
    'dordogne.pref.gouv.fr',
    'somme.pref.gouv.fr',
    'datasubvention.beta.gouv.fr',
    'anc.gouv.fr',
    'premar-mediterranee.gouv.fr',
    'ille-et-vilaine.pref.gouv.fr',
    'eure-et-loir.pref.gouv.fr',
    'prestataires.pm.gouv.fr',
    'snu.gouv.fr',
    'code.gouv.fr',
    'alsace.pref.gouv.fr',
    'haute-vienne.pref.gouv.fr',
    'yonne.pref.gouv.fr',
    'bretagne.pref.gouv.fr',
    'mastere.insp.gouv.fr',
    'cada.pm.gouv.fr',
    'creuse.pref.gouv.fr',
    'ecologie.gouv.fr',
    'midi-pyrenees.pref.gouv.fr',
    'promo54.ira-metz.gouv.fr',
    'var.pref.gouv.fr',
    'alpes-de-haute-provence.pref.gouv.fr',
    'mail.numerique.gouv.fr',
    'france-identite.gouv.fr',
    'transport.data.gouv.fr',
    'allier.pref.gouv.fr',
    'dilhal.gouv.fr',
    'ardeche.pref.gouv.fr',
    'haute-corse.pref.gouv.fr',
    'intérieur.gouv.fr',
    'ddfip.gouv.fr',
    'calvados.pref.gouv.fr',
    'territoir-de-belfort.gouv.fr',
    'nor.gouv.fr',
    'creps-occitanie.sports.gouv.fr',
    'developpement-durabe.gouv.fr',
    'educ.nat.gouv.fr',
    'developpement-duable.gouv.fr',
    'dgfip.finanes.gouv.fr',
    'loire-atlantqieu.gouv.fr',
    'promo55.ira-metz.gouv.fr',
    'haute-saône.gouv.fr',
    'developpement.durable.gouv.fr',
    'dreet.gouv.fr',
    'miprof.gouv.fr',
    'pref.guyane.gouv.fr',
    'developpement.gouv.fr',
    'gendamrerie.interieur.gouv.fr',
    'pyrenees-atlantique.gouv.fr',
    'apprentissage.beta.gouv.fr',
    'yveliens.gouv.fr',
    'justiice.gouv.fr',
    'cutlure.gouv.fr',
    'aidantsconnect.beta.gouv.fr',
    'developpement-durbale.gouv.fr',
    'sine-et-marne.gouv.fr',
    'sociale.gouv.fr',
    'develeoppement-durable.gouv.fr',
    'draaf.gouv.fr',
    'drets.gouv.fr',
    'ancli.gouv.fr',
    'finistrere.gouv.fr',
    'bourgogne.pref.gouv.fr',
    'ac-polynesie.pf',
    'ac-lille.fr',
    'ac-nantes.fr',
    'ac-martinique.fr',
    'ac-creteil.fr',
    'ac-toulouse.fr',
    'ac-amiensfr',
    'ac-amiens.fr',
    'ac-rennes.fr',
    'ac-strasbourg.fr',
    'ac-lyon.fr',
    'ac-versailles.fr',
    'ac-audit.fr',
    'ac-rouen.fr',
    'ac-reunion.fr',
    'ac-poitiers.fr',
    'ac-caen.fr',
    'ac-montpellier.fr',
    'ac-paris.fr',
    'ac-besancon.fr',
    'ac-nancy-metz.fr',
    'ac-aix-marseille.fr',
    'ac-grenoble.fr',
    'ac-corse.fr',
    'ac-nice.fr',
    'ac-orleans-tours.fr',
    'ac-guadeloupe.fr',
    'ac-reims.fr',
    'ac-mayotte.fr',
    'ac-clermont.fr',
    'ac-bordeaux.fr',
    'ac-limoges.fr',
    'ac-normandie.fr',
    'ac-dijon.fr',
    'ac-guyane.fr',
    'ac-transports.fr',
    'ac-arpajonnais.com',
    'ac-cned.fr',
    'ac-nettoyage.com',
    'ac-architectes.fr',
    'ac-ajaccio.corsica',
    'ac-noumea.nc',
    'ac-spm.fr',
    'ac-versailes.fr',
    'ac-polynesie.fr',
    'ac-experts.fr',
    'ac-creteil.com',
    'ac-smart-relocation.com',
    'ac-ec.pro',
    'ac-sas.fr',
    'ac-derma.de',
    'ac-or.com',
    'ac-baugeois.fr',
    'ac-5.ru',
    'ac-arles.fr',
    'ac-holding.net',
    'ac-mb.fr',
    'ac-wf.wf',
    'ac-brest-finistere.fr',
    'ac-leman.com',
    'ac-darboussier.fr',
    'ac-si.fr',
    'ac-bordeau.fr',
    'ac-gatinais.com',
    'ac-cheminots.fr',
    'ac-seyssinet.com',
    'ac-cannes.fr',
    'ac-prev.com',
    'ac-sologne.fr',
    'ac-rennes',
    'ac-courbevoie.com',
    'ac-ce.fr',
    'ac-architecte.fr',
    'ac-tions.org',
    'ac-pm.fr',
    'ac-avocats.com',
    'ac-talents-rh.com',
    'ac-louis.com',
    'ac-internet.fr',
    'ac-toulouse.com',
    'ac-escial.fr',
    'ac-environnement.com',
    'ac-academie.fr',
    'ac-poiters.fr',
    'ac-bordeux.fr',
    'ac-verseilles.fr',
    'ac-ais-marseille.fr',
    'ac-horizon.fr',
    'ac-bordeaux.ft',
    'ac-toulouses.fr',
    'ac-toulous.fr'
  ].freeze

  def check(email:)
    return { success: false } if email.blank?

    parsed_email = Mail::Address.new(EmailSanitizableConcern::EmailSanitizer.sanitize(email))
    return { success: false } if parsed_email.domain.blank?

    return { success: true } if KNOWN_DOMAINS.any? { _1 == parsed_email.domain }

    similar_domains = closest_domains(domain: parsed_email.domain)
    return { success: true } if similar_domains.empty?

    { success: true, email_suggestions: email_suggestions(parsed_email:, similar_domains:) }
  rescue Mail::Field::IncompleteParseError
    return { success: false }
  end

  private

  def closest_domains(domain:)
    KNOWN_DOMAINS.filter do |known_domain|
      close_by_distance_of(domain, known_domain, distance: 1) ||
      with_same_chars_and_close_by_distance_of(domain, known_domain, distance: 2)
    end
  end

  def close_by_distance_of(a, b, distance:)
    String::Similarity.levenshtein_distance(a, b) == distance
  end

  def with_same_chars_and_close_by_distance_of(a, b, distance:)
    close_by_distance_of(a, b, distance: 2) && a.chars.sort == b.chars.sort
  end

  def email_suggestions(parsed_email:, similar_domains:)
    similar_domains.map { Mail::Address.new("#{parsed_email.local}@#{_1}").to_s }
  end
end