require "net/http"
require "uri"
require "fileutils"
require "colorize"
require_relative "ssl_helper"

module Archivetok
  class Downloader
    include SslHelper
    DESKTOP_UA   = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 " \
                   "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    MAX_REDIRECTS = 5

    def initialize(config)
      @output_dir        = config.output_dir
      @json_sidecar      = config.json_sidecar
      @filename_username = config.filename_username
      @filename_date     = config.filename_date
      @filename_id       = config.filename_id
      @filename_slug     = config.filename_slug
      FileUtils.mkdir_p(@output_dir)
    end

    def save_video(data, source_url)
      filename = build_filename(data[:author_id], data[:create_time], data[:video_id], "mp4",
                                description: data[:description])
      path     = File.join(@output_dir, filename)
      puts "  Downloading video...".white
      write_binary(data[:video_url], path, source_url, cookies: data[:cookies])
      puts "  Saved: #{filename}".green
      write_sidecar(base_path(path), data, source_url)
    end

    def save_images(data, image_urls, source_url)
      image_urls.each_with_index do |img_url, i|
        filename = build_filename(data[:author_id], data[:create_time], data[:media_id], "jpg",
                                  index: i + 1, description: data[:description])
        path     = File.join(@output_dir, filename)
        puts "  Downloading image #{i + 1}/#{image_urls.size}...".white
        write_binary(img_url, path, source_url, cookies: data[:cookies])
        puts "  Saved: #{filename}".green
      end
      sidecar_base = File.join(@output_dir, build_filename(data[:author_id], data[:create_time],
                                                           data[:media_id], "sidecar",
                                                           description: data[:description])
                                                .sub(/\.sidecar\z/, ""))
      write_sidecar(sidecar_base, data, source_url)
    end

    private

    def build_filename(author_id, timestamp, media_id, ext, index: nil, description: nil)
      parts = []
      parts << author_id                                        if @filename_username
      parts << format_date(timestamp)                          if @filename_date
      parts << ((description && slugify(description)) || nil)  if @filename_slug
      parts << media_id                                        if @filename_id
      parts.compact!
      parts << media_id if parts.empty?  # always need something
      parts << index.to_s.rjust(2, "0") if index
      "#{parts.join('-')}.#{ext}"
    end

    def slugify(text, max_words: 8, min_sentence_words: 5)
      return nil if text.nil? || text.strip.empty?

      # Try first sentence — use it if it lands in the sweet spot (5+ words)
      if (m = text.match(/\A(.+?)[.!?](?:\s|$)/))
        sentence_words = m[1].downcase.gsub(/[''']/, "").gsub(/[^a-z0-9]+/, " ").strip.split
        if sentence_words.length >= min_sentence_words
          return sentence_words.first(max_words).join("-")
        end
      end

      # Fall back to first max_words words of full text
      words = text.downcase.gsub(/[''']/, "").gsub(/[^a-z0-9]+/, " ").strip.split
      slug  = words.first(max_words).join("-")
      slug.empty? ? nil : slug
    end

    def format_date(unix_ts)
      Time.at(unix_ts.to_i).strftime("%Y-%m-%d")
    end

    def base_path(path)
      path.sub(/\.[^.]+\z/, "")
    end

    def write_binary(url, path, referer, cookies: nil, redirect_count: 0)
      raise "Too many redirects" if redirect_count > MAX_REDIRECTS

      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = DESKTOP_UA
      req["Referer"]    = referer
      req["Cookie"]     = cookies if cookies && !cookies.empty?

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                      cert_store: ssl_store,
                      open_timeout: 15, read_timeout: 120) do |http|
        http.request(req) do |response|
          case response
          when Net::HTTPSuccess
            File.open(path, "wb") { |f| response.read_body { |chunk| f.write(chunk) } }
          when Net::HTTPRedirection
            write_binary(response["location"], path, referer, cookies: cookies, redirect_count: redirect_count + 1)
          else
            raise "Download HTTP #{response.code} for #{url}"
          end
        end
      end
    end

    def write_sidecar(base, data, source_url)
      if @json_sidecar
        write_json_sidecar("#{base}.json", data, source_url)
      else
        write_txt_sidecar("#{base}.txt", data, source_url)
      end
    end

    def write_txt_sidecar(path, data, source_url)
      date = Time.at(data[:create_time].to_i).strftime("%Y-%m-%d")
      id   = data[:video_id] || data[:media_id]
      File.write(path, <<~TXT)
        Title:       #{data[:description]}
        Author:      #{data[:author_name]} (@#{data[:author_id]})
        Date:        #{date}
        Video ID:    #{id}
        Source URL:  #{source_url}
      TXT
      puts "  Saved: #{File.basename(path)}".green
    end

    def write_json_sidecar(path, data, source_url)
      require "json"
      date = Time.at(data[:create_time].to_i).strftime("%Y-%m-%d")
      id   = data[:video_id] || data[:media_id]
      payload = {
        title:      data[:description],
        author:     { name: data[:author_name], username: data[:author_id] },
        date:       date,
        video_id:   id,
        source_url: source_url
      }
      File.write(path, JSON.pretty_generate(payload))
      puts "  Saved: #{File.basename(path)}".green
    end
  end
end
