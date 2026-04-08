require "net/http"
require "uri"
require "json"
require "nokogiri"
require_relative "ssl_helper"

module Archivetok
  module PageFetcher
    include SslHelper

    DESKTOP_UA   = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 " \
                   "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    MAX_REDIRECTS = 3

    def fetch_html(url, redirect_count = 0)
      raise "Too many redirects" if redirect_count > MAX_REDIRECTS

      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"]      = DESKTOP_UA
      req["Accept"]          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      req["Accept-Language"] = "en-US,en;q=0.5"
      req["Cookie"]          = cookie_header unless @cookies.empty?

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 cert_store: ssl_store,
                                 open_timeout: 15, read_timeout: 30) do |http|
        http.request(req)
      end

      collect_cookies(response)

      case response
      when Net::HTTPSuccess    then response.body
      when Net::HTTPRedirection then fetch_html(response["location"], redirect_count + 1)
      else raise "HTTP #{response.code} for #{url}"
      end
    end

    def parse_rehydration_json(html)
      doc    = Nokogiri::HTML(html)
      script = doc.at_css("script#__UNIVERSAL_DATA_FOR_REHYDRATION__")
      return nil unless script
      JSON.parse(script.text)
    rescue JSON::ParserError
      nil
    end

    def collect_cookies(response)
      (response.get_fields("set-cookie") || []).each do |cookie_str|
        name, value = cookie_str.split(";").first.to_s.split("=", 2)
        @cookies[name.strip] = value.to_s.strip if name
      end
    end

    def cookie_header
      @cookies.map { |k, v| "#{k}=#{v}" }.join("; ")
    end
  end
end
