require 'fog/openstack'

class ActiveStorage::DownloadableFile
<<<<<<< HEAD
<<<<<<< HEAD
  def self.create_list_from_dossiers(
    dossiers,
    with_bills: false,
    with_champs_private: false,
    include_infos_administration: false,
    include_avis_for_expert: false
  )
    PiecesJustificativesService.generate_dossier_export(dossiers, include_infos_administration:, include_avis_for_expert:) +
      PiecesJustificativesService.liste_documents(dossiers, with_bills:, with_champs_private:, with_avis_piece_justificative: include_infos_administration)
=======
=======
>>>>>>> 6ae81dddb (wip(pending): w8 for now)
  # TODO, refactor using user asking for the list from dossiers
  # instead of using flags from caller
  # we do a big switch extracting those flag here
  def self.create_list_from_dossiers(dossiers, user_profile)
    acls = acl_for_liste_documents(user_profile)
<<<<<<< HEAD
    PiecesJustificativesService.generate_dossier_export(dossiers, user_profile) +
      PiecesJustificativesService.liste_documents(dossiers, user_profile)
>>>>>>> ed52aae17 (wip)
=======
    PiecesJustificativesService.generate_dossier_export(dossiers, acls.slice(:include_infos_administration, :include_avis_for_expert)) +
      PiecesJustificativesService.liste_documents(dossiers, acls.slice(:with_bills, :with_champs_private, :with_avis_piece_justificative, :include_infos_administration))
  end

  def self.acl_for_liste_documents(user_profile)
    acl_for_user_profile = case user_profile
    when Expert
      { include_avis_for_expert: current_expert }
    when Instructeur
      { with_champs_private: true, include_infos_administration: true }
    end
    default_acls.merge(acl_for_user_profile)
  end

  def self.default_acls
    {
      with_bills: false,
      with_champs_private: false,
      include_infos_administration: false,
      include_avis_for_expert: false
    }
>>>>>>> 6ae81dddb (wip(pending): w8 for now)
  end

  def self.cleanup_list_from_dossier(files)
    if Rails.application.config.active_storage.service != :openstack
      return files
    end

    files.filter do |file, _filename|
      if file.is_a?(ActiveStorage::FakeAttachment)
        true
      else
        service = file.blob.service
        begin
          client.head_object(service.container, file.blob.key)
          true
        rescue Fog::OpenStack::Storage::NotFound
          false
        end
      end
    end
  end

  private

  def self.client
    credentials = Rails.application.config.active_storage
      .service_configurations['openstack']['credentials']

    Fog::OpenStack::Storage.new(credentials)
  end

  def self.bill_and_path(bill)
    [
      bill,
      "bills/#{self.timestamped_filename(bill)}"
    ]
  end

  def self.pj_and_path(dossier_id, pj)
    [
      pj,
      "dossier-#{dossier_id}/#{self.timestamped_filename(pj)}"
    ]
  end

  def self.timestamped_filename(attachment)
    # we pad the original file name with a timestamp
    # and a short id in order to help identify multiple versions and avoid name collisions
    folder = self.folder(attachment)
    extension = File.extname(attachment.filename.to_s)
    basename = File.basename(attachment.filename.to_s, extension)
    timestamp = attachment.created_at.strftime("%d-%m-%Y-%H-%M")
    id = attachment.id % 10000

    [folder, "#{basename}-#{timestamp}-#{id}#{extension}"].join
  end

  def self.folder(attachment)
    if attachment.name == 'pdf_export_for_instructeur'
      return ''
    end

    case attachment.record_type
    when 'Dossier'
      'dossier/'
    when 'DossierOperationLog', 'BillSignature'
      'horodatage/'
    when 'Commentaire'
      'messagerie/'
    when 'Avis'
      'avis/'
    else
      'pieces_justificatives/'
    end
  end
end
