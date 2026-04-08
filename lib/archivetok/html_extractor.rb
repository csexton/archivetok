require_relative "page_fetcher"

module Archivetok
  class HtmlExtractor
    include PageFetcher

    def self.extract(url)
      new(url).extract
    end

    def initialize(url)
      @url     = url
      @cookies = {}
    end

    def extract
      html = fetch_html(@url)
      json = parse_rehydration_json(html)
      return nil unless json
      data = build_video_data(json)
      return nil unless data
      data.merge(cookies: cookie_header)
    rescue => e
      $stderr.puts "  HTML extraction error: #{e.message}".yellow
      nil
    end

    private

    def build_video_data(json)
      video_detail = json.dig("__DEFAULT_SCOPE__", "webapp.video-detail")
      return nil unless video_detail
      item   = video_detail.dig("itemInfo", "itemStruct")
      return nil unless item
      author = item["author"]
      video  = item["video"]
      return nil unless author && video
      video_url = extract_video_url(video)
      return nil unless video_url
      {
        author_id:   author["uniqueId"].to_s,
        author_name: author["nickname"].to_s,
        video_id:    item["id"].to_s,
        create_time: item["createTime"].to_i,
        video_url:   video_url,
        description: item["desc"].to_s
      }
    end

    def extract_video_url(video)
      video.dig("bitrateInfo", 0, "PlayAddr", "UrlList", 0) || video["playAddr"]
    end
  end
end
