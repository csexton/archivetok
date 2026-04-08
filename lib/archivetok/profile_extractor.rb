require "securerandom"
require_relative "page_fetcher"

module Archivetok
  class ProfileExtractor
    include PageFetcher

    VIDEOS_PER_PAGE = 15
    API_URL         = "https://www.tiktok.com/api/creator/item_list/"
    # Earliest possible TikTok createTime (Jan 2 2016), used as stop sentinel
    TIKTOK_EPOCH_MS = 1_451_692_800_000

    def self.extract(url, pages: 1)
      new(url, pages: pages).extract
    end

    def initialize(url, pages: 1)
      @url       = url
      @pages     = pages
      @cookies   = {}
      @device_id = random_device_id
    end

    def extract
      html    = fetch_html(@url)
      json    = parse_rehydration_json(html)
      unless json
        $stderr.puts "  Could not parse profile page".red
        return []
      end

      sec_uid  = json.dig("__DEFAULT_SCOPE__", "webapp.user-detail", "userInfo", "user", "secUid")
      username = extract_username_from_url

      unless sec_uid
        $stderr.puts "  Could not find secUid in profile page".red
        return []
      end

      items  = []
      cursor = (Time.now.to_f * 1000).to_i  # start at now, walk backwards

      @pages.times do |i|
        $stderr.puts "  Fetching page #{i + 1}...".blue
        result = fetch_page(sec_uid, cursor)
        break unless result

        page_items = result["itemList"] || []
        break if page_items.empty?

        $stderr.puts "  Found #{page_items.size} video(s)".blue
        items += page_items

        # Cursor for next page = createTime of last item in milliseconds
        last_create_time = page_items.last&.dig("createTime")
        break unless last_create_time

        new_cursor = (last_create_time.to_f * 1000).to_i
        # If cursor didn't advance, step back 7 days to avoid infinite loop
        cursor = (new_cursor == cursor) ? cursor - 7 * 86_400_000 : new_cursor

        break if cursor < TIKTOK_EPOCH_MS
        break unless result["hasMorePrevious"]
      end

      items.map do |item|
        uname = item.dig("author", "uniqueId") || username
        "https://www.tiktok.com/@#{uname}/video/#{item["id"]}"
      end
    rescue => e
      $stderr.puts "  Profile extraction error: #{e.message}".red
      []
    end

    private

    def fetch_page(sec_uid, cursor)
      uri = URI.parse(API_URL)
      uri.query = URI.encode_www_form(build_query(sec_uid, cursor))

      req = Net::HTTP::Get.new(uri)
      req["User-Agent"]      = DESKTOP_UA
      req["Referer"]         = @url
      req["Accept"]          = "application/json, text/plain, */*"
      req["Accept-Language"] = "en-US,en;q=0.5"
      req["Cookie"]          = cookie_header unless @cookies.empty?

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 cert_store: ssl_store, open_timeout: 15, read_timeout: 30) do |http|
        http.request(req)
      end

      collect_cookies(response)

      unless response.is_a?(Net::HTTPSuccess)
        $stderr.puts "  API HTTP #{response.code}".yellow
        return nil
      end

      if response.body.empty?
        $stderr.puts "  API returned empty body (bad device_id, retrying with new one)".yellow
        @device_id = random_device_id
        return nil
      end

      JSON.parse(response.body)
    rescue => e
      $stderr.puts "  API request failed: #{e.message}".yellow
      nil
    end

    def build_query(sec_uid, cursor)
      {
        aid:              "1988",
        app_language:     "en",
        app_name:         "tiktok_web",
        browser_language: "en-US",
        browser_name:     "Mozilla",
        browser_online:   "true",
        browser_platform: "Win32",
        browser_version:  "5.0 (Windows)",
        channel:          "tiktok_web",
        cookie_enabled:   "true",
        count:            VIDEOS_PER_PAGE.to_s,
        cursor:           cursor.to_s,
        device_id:        @device_id,
        device_platform:  "web_pc",
        focus_state:      "true",
        from_page:        "user",
        history_len:      "2",
        is_fullscreen:    "false",
        is_page_visible:  "true",
        language:         "en",
        os:               "windows",
        priority_region:  "",
        referer:          "",
        region:           "US",
        screen_height:    "1080",
        screen_width:     "1920",
        secUid:           sec_uid,
        type:             "1",
        tz_name:          "UTC",
        verifyFp:         "verify_#{SecureRandom.hex(4)[0, 7]}",
        webcast_language: "en",
      }
    end

    def extract_username_from_url
      @url.match(/@([\w.]+)/)&.captures&.first
    end

    def random_device_id
      rand(7_250_000_000_000_000_000..7_325_099_899_999_994_577).to_s
    end
  end
end
