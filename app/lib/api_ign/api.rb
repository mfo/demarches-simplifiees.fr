# frozen_string_literal: true

class APIIgn::API
  include Dry::Monads[:result]

  def self.fetch_parcelle(id:)
    uri = URI("https://data.geopf.fr/geocodage/search")
    uri.query = URI.encode_www_form({ q: id, index: 'parcel', returntruegeometry: "1" })

    result = API::Client.new.(url: uri.to_s)

    case result
    in Success(body:)
      body.dig(:features, 0, :properties, :truegeometry)
    else
      raise ArgumentError, "Lookup error: #{result.inspect}"
    end
  end

  WMS_URL = "https://data.geopf.fr/wms-r/wms"
  WMS_TIMEOUT = 20
  ORTHOPHOTOS_LAYER = { name: 'ORTHOIMAGERY.ORTHOPHOTOS', transparent: false }.freeze
  # Carries the place names, but only past a certain extent: closer in, it draws
  # nothing but the commune boundary line, which cuts across the photo without
  # telling us anything.
  ADMINEXPRESS_LAYER = { name: 'ADMINEXPRESS-COG-CARTO.LATEST', transparent: true }.freeze
  # Extent (in EPSG:3857 metres, roughly two thirds of a metre on the ground at
  # French latitudes) past which the place names show up. Calibrated on
  # successive renders: nothing at 1,500 m, communes named at 3,700 m.
  ADMINEXPRESS_MIN_SPAN = 3000

  # Fetches, in parallel, the basemaps covering `bbox` (in EPSG:3857, as
  # [min_x, min_y, max_x, max_y]). Returns the encoded images, bottom layer
  # first.
  #
  # Note: `API::Client` is unusable here, it parses responses as JSON.
  def self.fetch_wms_layers(bbox:, size:)
    layers = wms_layers_for(bbox)
    hydra = Typhoeus::Hydra.new(max_concurrency: layers.size)
    requests = layers.map do |layer|
      Typhoeus::Request.new(wms_url(layer, bbox, size), timeout: WMS_TIMEOUT)
        .tap { hydra.queue(it) }
    end
    hydra.run

    requests.map { handle_wms_response(it.response) }
  end

  def self.wms_layers_for(bbox)
    if bbox[2] - bbox[0] >= ADMINEXPRESS_MIN_SPAN
      [ORTHOPHOTOS_LAYER, ADMINEXPRESS_LAYER]
    else
      [ORTHOPHOTOS_LAYER]
    end
  end

  def self.wms_url(layer, bbox, size)
    params = {
      SERVICE: 'WMS',
      VERSION: '1.3.0',
      REQUEST: 'GetMap',
      STYLES: '',
      LAYERS: layer[:name],
      FORMAT: 'image/png',
      CRS: 'EPSG:3857',
      # In WMS 1.3.0 the axis order depends on the CRS: x,y for EPSG:3857,
      # but lat,lon for EPSG:4326.
      BBOX: bbox.join(','),
      WIDTH: size,
      HEIGHT: size,
      TRANSPARENT: layer[:transparent].to_s.upcase,
    }

    "#{WMS_URL}?#{URI.encode_www_form(params)}"
  end
  private_class_method :wms_url

  # The service answers 200 with an XML ServiceExceptionReport when it dislikes
  # the request: the HTTP status alone is not enough to validate the response.
  def self.handle_wms_response(response)
    if !response.success?
      raise RetryableFetchError, "WMS IGN: #{response.code} #{response.return_message}"
    elsif !response.headers['Content-Type'].to_s.start_with?('image/')
      raise RetryableFetchError, "WMS IGN: unexpected response (#{response.headers['Content-Type']})"
    end

    response.body
  end
  private_class_method :handle_wms_response
end
