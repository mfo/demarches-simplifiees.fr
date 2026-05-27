/**
 * Helpers pour générer un libellé lisible à partir d'un attribut HTML `accept`.
 *
 * L'attribut `accept` côté Ruby (Attachment::Validation#content_types_with_extensions)
 * concatène volontairement MIME types ET extensions (.ext) pour la compatibilité
 * navigateur. Ces helpers s'occupent de produire un texte unique pour l'utilisateur
 * sans dupliquer chaque extension (une fois via label famille, une fois via .ext).
 */

/**
 * Retourne le label d'une famille de formats à partir d'une catégorie MIME (image, video, …).
 * Basé sur FORMAT_FAMILY_EXAMPLES de config/initializers/authorized_content_types.rb
 */
function getFormatFamilyLabel(mimeCategory: string): string {
  const formatFamilyLabels: Record<string, string> = {
    // Correspond à FORMAT_FAMILY_EXAMPLES[:image_scan]
    image: '.jpg, .jpeg, .png',
    // Correspond à FORMAT_FAMILY_EXAMPLES[:video]
    video: '.mp4, .mov, .avi, .wmv',
    // Correspond à FORMAT_FAMILY_EXAMPLES[:audio]
    audio: '.mp3, .wav, .aac, .m4a',
    // Correspond à FORMAT_FAMILY_EXAMPLES[:document_texte] (partiel)
    application: '.pdf, .doc, .docx, .odt, .txt',
    // Correspond à FORMAT_FAMILY_EXAMPLES[:donnees] (partiel)
    text: '.xml, .json, .txt, .csv'
  };

  return formatFamilyLabels[mimeCategory] || mimeCategory;
}

/**
 * Convertit un MIME type exact vers son label famille.
 * Mapping basé sur FORMAT_FAMILIES (config/initializers/authorized_content_types.rb)
 */
function getMimeTypeLabel(mimeType: string): string | null {
  // Mapping des MIME types utilisés dans FORMAT_FAMILIES vers leurs labels
  const mimeToFamilyLabel: Record<string, string> = {
    // image_scan → '.jpg, .jpeg, .png'
    'image/jpeg': '.jpg, .jpeg, .png',
    'image/png': '.jpg, .jpeg, .png',

    // document_texte → '.pdf, .doc, .docx, .odt, .txt'
    'application/pdf': '.pdf, .doc, .docx, .odt, .txt',
    'application/x-pdf': '.pdf, .doc, .docx, .odt, .txt',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      '.pdf, .doc, .docx, .odt, .txt',
    'application/vnd.oasis.opendocument.text': '.pdf, .doc, .docx, .odt, .txt',
    'application/msword': '.pdf, .doc, .docx, .odt, .txt',
    'text/plain': '.pdf, .doc, .docx, .odt, .txt',

    // tableur → '.xls, .xlsx, .ods, .csv'
    'application/vnd.ms-excel': '.xls, .xlsx, .ods, .csv',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      '.xls, .xlsx, .ods, .csv',
    'application/vnd.oasis.opendocument.spreadsheet': '.xls, .xlsx, .ods, .csv',
    'text/csv': '.xls, .xlsx, .ods, .csv',

    // presentation → '.ppt, .pptx, .odp'
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      '.ppt, .pptx, .odp',
    'application/vnd.ms-powerpoint': '.ppt, .pptx, .odp',

    // audio → '.mp3, .wav, .aac, .m4a'
    'audio/mpeg': '.mp3, .wav, .aac, .m4a',
    'audio/mp4': '.mp3, .wav, .aac, .m4a',
    'audio/x-m4a': '.mp3, .wav, .aac, .m4a',
    'audio/aac': '.mp3, .wav, .aac, .m4a',
    'audio/x-wav': '.mp3, .wav, .aac, .m4a',

    // video → '.mp4, .mov, .avi, .wmv'
    'video/mp4': '.mp4, .mov, .avi, .wmv',
    'video/quicktime': '.mp4, .mov, .avi, .wmv',
    'video/3gpp': '.mp4, .mov, .avi, .wmv',
    'video/x-ms-wm': '.mp4, .mov, .avi, .wmv',

    // archive → '.zip, .rar, .7z, .gz'
    'application/zip': '.zip, .rar, .7z, .gz',
    'application/x-zip-compressed': '.zip, .rar, .7z, .gz',
    'application/x-7z-compressed': '.zip, .rar, .7z, .gz',
    'application/vnd.rar': '.zip, .rar, .7z, .gz',
    'application/x-rar': '.zip, .rar, .7z, .gz',
    'application/gzip': '.zip, .rar, .7z, .gz'
  };

  return mimeToFamilyLabel[mimeType] || null;
}

/**
 * Extrait les extensions (sans point, en minuscules) d'un label famille
 * du type ".pdf, .doc, .docx".
 */
function extensionsFromLabel(label: string): string[] {
  return label
    .split(',')
    .map((token) => token.trim().replace(/^\./, '').toLowerCase())
    .filter((ext) => ext.length > 0);
}

/**
 * Parse l'attribut accept pour générer un label lisible.
 *
 * L'attribut accept produit côté Ruby contient à la fois les MIME types
 * et leurs extensions (.ext). Pour éviter d'afficher chaque extension deux
 * fois, on émet d'abord les labels famille (issus des MIME types), puis on
 * n'ajoute que les .ext qui ne sont couvertes par aucun label.
 *
 * @example ".pdf, .docx" → "PDF, DOCX"
 * @example "image/*" → ".jpg, .jpeg, .png"
 * @example "application/pdf, .pdf" → ".pdf, .doc, .docx, .odt, .txt"
 */
export function parseAcceptForDisplay(accept: string): string {
  const acceptedFormats = accept
    .split(',')
    .map((format) => format.trim().toLowerCase())
    .filter((format) => format.length > 0);

  const familyLabels: string[] = [];
  const coveredExtensions = new Set<string>();
  const standaloneExtensions: string[] = [];

  for (const format of acceptedFormats) {
    if (format.startsWith('.')) {
      const ext = format.substring(1);
      if (ext.length > 0 && !standaloneExtensions.includes(ext)) {
        standaloneExtensions.push(ext);
      }
    } else if (format.includes('/*')) {
      const category = format.split('/')[0];
      const label = getFormatFamilyLabel(category);
      if (!familyLabels.includes(label)) {
        familyLabels.push(label);
        for (const ext of extensionsFromLabel(label)) {
          coveredExtensions.add(ext);
        }
      }
    } else {
      const label = getMimeTypeLabel(format);
      if (label && !familyLabels.includes(label)) {
        familyLabels.push(label);
        for (const ext of extensionsFromLabel(label)) {
          coveredExtensions.add(ext);
        }
      }
    }
  }

  const uncoveredExtensions = standaloneExtensions
    .filter((ext) => !coveredExtensions.has(ext))
    .map((ext) => ext.toUpperCase());

  const displayItems = [...familyLabels, ...uncoveredExtensions];

  // Si aucune extension/wildcard/MIME type reconnu, message générique
  if (displayItems.length === 0) {
    return 'certains formats spécifiques';
  }

  return displayItems.join(', ');
}
