module Archivetok
  module UrlValidator
    PATTERN = %r{\Ahttps?://(www\.|vm\.)?tiktok\.com/}

    def self.valid?(url)
      url.is_a?(String) && PATTERN.match?(url)
    end

    def self.photo?(url)
      url.include?("/photo/")
    end

    def self.profile?(url)
      uri = URI.parse(url)
      uri.path.match?(%r{\A/@[\w.]+/?$})
    rescue URI::InvalidURIError
      false
    end
  end
end
