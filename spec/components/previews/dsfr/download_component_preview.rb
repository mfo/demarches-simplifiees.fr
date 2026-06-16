# frozen_string_literal: true

class Dsfr::DownloadComponentPreview < ViewComponent::Preview
  def default
    attachment = Struct.new(:filename, :byte_size).new(
      Struct.new(:extension).new('pdf'),
      12_345
    )
    render Dsfr::DownloadComponent.new(attachment:, url: '/rails/view_components/download_sample.pdf')
  end

  def with_name
    attachment = Struct.new(:filename, :byte_size).new(
      Struct.new(:extension).new('pdf'),
      12_345
    )
    render Dsfr::DownloadComponent.new(attachment:, name: 'Mon fichier', has_name: true,
      url: '/rails/view_components/download_sample.pdf')
  end

  def with_ephemeral_link
    attachment = Struct.new(:filename, :byte_size).new(
      Struct.new(:extension).new('pdf'),
      12_345
    )
    render Dsfr::DownloadComponent.new(attachment:, ephemeral_link: true,
      url: '/rails/view_components/download_sample.pdf')
  end

  def with_virus_not_analyzed
    attachment = Struct.new(:filename, :byte_size).new(
      Struct.new(:extension).new('pdf'),
      12_345
    )
    render Dsfr::DownloadComponent.new(attachment:, virus_not_analyzed: true,
      url: '/rails/view_components/download_sample.pdf')
  end

  def full
    attachment = Struct.new(:filename, :byte_size).new(
      Struct.new(:extension).new('pdf'),
      12_345
    )
    render Dsfr::DownloadComponent.new(attachment:, name: 'Mon fichier', has_name: true,
      ephemeral_link: true, virus_not_analyzed: true, url: '/rails/view_components/download_sample.pdf')
  end
end
