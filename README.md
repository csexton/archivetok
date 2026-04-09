# archivetok

A Ruby CLI for downloading TikTok videos and photos without watermarks, including metadata sidecars.

Based on [tiktok-downloader-console](https://github.com/RehanDias/tiktok-downloader-console) by [rehandiazz](https://github.com/RehanDias).

## Usage

```bash
bundle exec bin/archivetok URL [URL...] [options]
```

```bash
# Download a video to the current directory
bundle exec bin/archivetok https://www.tiktok.com/@someuser/video/1234567890

# Specify an output directory
bundle exec bin/archivetok --output-dir ~/Downloads/tiktok https://www.tiktok.com/@someuser/video/1234567890

# Save sidecar as JSON instead of plain text
bundle exec bin/archivetok --json https://www.tiktok.com/@someuser/video/1234567890

# Download multiple URLs
bundle exec bin/archivetok URL1 URL2 URL3

# List all video URLs for a profile (prints to stdout, status to stderr)
bundle exec bin/archivetok https://www.tiktok.com/@someuser

# Fetch more pages of a profile
bundle exec bin/archivetok --pages 3 https://www.tiktok.com/@someuser

# Pipe profile listing into a download run
bundle exec bin/archivetok https://www.tiktok.com/@someuser | xargs bundle exec bin/archivetok
```

The output directory is created automatically if it doesn't exist.

## Configuration

Create a YAML config file to set defaults. The local project file takes precedence over the home file.

**`~/.archivetok.yml`** — user-wide defaults  
**`./.archivetok.yml`** — per-project override

```yaml
output_dir: ~/Downloads/tiktok
json_sidecar: true

# Filename components (all optional, shown with defaults)
filename_username: true
filename_date: true
filename_slug: true
filename_id: false
```

CLI flags override config file values.

## Output

Files are named from up to four components, each toggleable:

```
{username}-{YYYY-MM-DD}-{description-slug}.mp4
{username}-{YYYY-MM-DD}-{description-slug}.txt   # or .json with --json
```

Example: `someuser-2025-04-07-pov-you-didnt-ask-for-this-content.mp4`

The description slug is taken from the first sentence of the caption if it's 5–8 words, otherwise the first 8 words. Punctuation is stripped and spaces become dashes.

Photo posts save each image plus a single metadata sidecar for the set.

### Filename options

| Flag | Default | Description |
|------|---------|-------------|
| `--[no-]username` | on | Include the author's username |
| `--[no-]date` | on | Include the post date |
| `--[no-]slug` | on | Include a slug from the description |
| `--[no-]id` | off | Include the numeric video ID |

```bash
# Slug only
bundle exec bin/archivetok --no-username --no-date https://www.tiktok.com/@someuser/video/1234567890

# Add the ID for guaranteed uniqueness
bundle exec bin/archivetok --id https://www.tiktok.com/@someuser/video/1234567890
```

### Sidecar format

The `.txt` sidecar contains:

```
Title:       POV you didn't ask for this content
Author:      Some User (@someuser)
Date:        2025-04-07
Video ID:    1234567890
Source URL:  https://www.tiktok.com/@someuser/video/1234567890
```

With `--json`:

```json
{
  "title": "POV you didn't ask for this content",
  "author": { "name": "Some User", "username": "someuser" },
  "date": "2025-04-07",
  "video_id": "1234567890",
  "source_url": "https://www.tiktok.com/@someuser/video/1234567890"
}
```

## Setup

```bash
bundle install
```

Requires Ruby 2.6+.

## Credits

This is a Ruby port of [tiktok-downloader-console](https://github.com/RehanDias/tiktok-downloader-console) by [rehandiazz](https://github.com/RehanDias), which provides the original Node.js implementation and the fallback API endpoint.

## License

MIT
