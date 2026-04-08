# tiktok-downloader

A Ruby CLI for downloading TikTok videos and photos without watermarks, including metadata sidecars.

Based on [tiktok-downloader-console](https://github.com/RehanDias/tiktok-downloader-console) by [rehandiazz](https://github.com/RehanDias).

## Usage

```bash
bundle exec bin/tiktok-downloader URL [URL...] [--output-dir DIR]
```

```bash
# Download a video to the current directory
bundle exec bin/tiktok-downloader https://www.tiktok.com/@user/video/1234567890

# Specify an output directory
bundle exec bin/tiktok-downloader --output-dir ~/Downloads/tiktok https://www.tiktok.com/@user/video/1234567890

# Save sidecar as JSON instead of plain text
bundle exec bin/tiktok-downloader --json https://www.tiktok.com/@user/video/1234567890

# Download multiple URLs
bundle exec bin/tiktok-downloader URL1 URL2 URL3
```

The output directory is created automatically if it doesn't exist.

## Configuration

Create a YAML config file to set defaults. The local project file takes precedence over the home file.

**`~/.tiktok-downloader.yml`** — user-wide defaults
**`./.tiktok-downloader.yml`** — per-project override

```yaml
output_dir: ~/Downloads/tiktok
json_sidecar: true
```

CLI flags override config file values.

## Output

Each video is saved as:

```
{username}-{YYYY-MM-DD}-{video_id}.mp4
{username}-{YYYY-MM-DD}-{video_id}.txt   # metadata sidecar (or .json with --json)
```

For example: `deadrunwoodworks-2025-04-07-7602627380091440397.mp4`

Photo posts save each image plus a single metadata sidecar for the set.

The `.txt` sidecar contains:

```
Title:       Video caption text
Author:      Display Name (@username)
Date:        2025-04-07
Video ID:    7602627380091440397
Source URL:  https://www.tiktok.com/@user/video/7602627380091440397
```

With `--json`, a `.json` sidecar is saved instead:

```json
{
  "title": "Video caption text",
  "author": { "name": "Display Name", "username": "username" },
  "date": "2025-04-07",
  "video_id": "7602627380091440397",
  "source_url": "https://www.tiktok.com/@user/video/7602627380091440397"
}
```

## Setup

```bash
cd ruby
bundle install
```

Requires Ruby 2.6+.

## Credits

This is a Ruby port of [tiktok-downloader-console](https://github.com/RehanDias/tiktok-downloader-console) by [rehandiazz](https://github.com/RehanDias), which provides the original Node.js implementation and the fallback API endpoint.

## LICENSE

This project is licensed under the MIT License.
