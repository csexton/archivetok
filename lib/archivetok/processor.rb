require "colorize"

module Archivetok
  class Processor
    def initialize(config)
      @config     = config
      @downloader = Downloader.new(config)
    end

    def process(url)
      puts "\n=> Processing: #{url}".cyan
      if UrlValidator.photo?(url)
        process_photo(url)
      else
        process_video(url)
      end
    end

    private

    def process_video(url)
      puts "  Trying HTML extraction...".blue
      data = HtmlExtractor.extract(url)

      if data
        puts "  HTML extraction succeeded".blue
      else
        puts "  Falling back to API...".yellow
        raw  = ApiClient.fetch(url)
        raise "Invalid API response for video" unless raw&.dig("video", "playAddr")
        data = normalize_api_video(raw)
      end

      @downloader.save_video(data, url)
    end

    def process_photo(url)
      puts "  Fetching photo post via API...".blue
      raw = ApiClient.fetch(url)
      raise "Invalid API response for photo" unless raw&.dig("images")&.any?

      data = normalize_api_photo(raw)
      @downloader.save_images(data, raw["images"], url)
    end

    def normalize_api_video(raw)
      play_addr = raw.dig("video", "playAddr")
      video_url = play_addr.is_a?(Array) ? play_addr.first : play_addr
      {
        author_id:   raw.dig("author", "username").to_s,
        author_name: raw.dig("author", "nickname").to_s,
        video_id:    raw["id"].to_s,
        create_time: raw["createTime"].to_i,
        video_url:   video_url,
        description: raw["desc"].to_s
      }
    end

    def normalize_api_photo(raw)
      {
        author_id:   raw.dig("author", "username").to_s,
        author_name: raw.dig("author", "nickname").to_s,
        media_id:    raw["id"].to_s,
        create_time: raw["createTime"].to_i,
        description: raw["desc"].to_s
      }
    end
  end
end
