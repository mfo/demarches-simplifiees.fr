# frozen_string_literal: true

module DownloadHelpers
  # Le zip est écrit dans Capybara.save_path pendant que le test attend. On ne
  # peut pas se contenter de constater sa présence : le fichier final apparaît
  # avant que le premier octet y soit écrit, et `Zip::File.open` sur un fichier
  # de 0 octet lève « has zero size ». On attend donc que sa taille soit non
  # nulle *et* stable d'un tour de boucle à l'autre.
  TIMEOUT = 5
  POLL = 0.1

  # Certains navigateurs écrivent d'abord dans un fichier temporaire posé à côté
  # du fichier final : .crdownload sous Chromium, .part sous Firefox.
  PARTIAL_EXTENSIONS = ['.crdownload', '.part'].freeze

  extend self

  def downloads
    Dir[Capybara.save_path.join("*.zip")]
  end

  def download
    downloads.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      previous_sizes = nil

      until downloaded?(previous_sizes)
        previous_sizes = sizes
        sleep POLL
      end
    end
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end

  private

  def downloaded?(previous_sizes)
    return false if downloading?

    current = sizes
    current.any? && current.all? && current == previous_sizes
  end

  def downloading?
    Dir[Capybara.save_path.join("*")]
      .any? { PARTIAL_EXTENSIONS.include?(File.extname(it)) }
  end

  # File.size? renvoie nil pour un fichier absent ou vide, ce qui suffit à
  # disqualifier le tour de boucle sans avoir à gérer ENOENT séparément.
  def sizes
    downloads.map { File.size?(it) }
  end
end
