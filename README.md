# mp3fixer

🎵 Smart Bash utility for renaming audio files using metadata tags.

`mp3fixer` automatically renames your music files into:

```text
Artist - Title.ext
````

using metadata extracted via `ffprobe`.

---

## Features

* 🎵 Metadata-based renaming
* 🔁 Recursive directory scanning
* 🧪 Dry-run preview mode
* 🛡 Collision protection
* 🧼 Safe filename sanitization
* ⚡ Fast and lightweight
* 🐧 Linux/macOS compatible
* 🔧 Powered by ffprobe (ffmpeg)

---

## Supported Formats

* mp3
* flac
* m4a
* wav
* aac
* ogg

---

# Quick Install

## One-line installer

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/WhoisGray/mp3fixer/refs/heads/main/install.sh)
```

or:

```bash
curl -fsSL https://raw.githubusercontent.com/WhoisGray/mp3fixer/refs/heads/main/install.sh | bash
```

GitHub raw URLs are commonly used to distribute install scripts directly from repositories. ([codegenes][1])

---

# Requirements

## Ubuntu / Debian

```bash
sudo apt install ffmpeg
```

## macOS

```bash
brew install ffmpeg
```

---

# Usage

## Rename Single File

```bash
mp3fixer song.mp3
```

---

## Rename Entire Music Folder

```bash
mp3fixer ~/Music
```

---

## Dry Run Mode

Preview changes without renaming files:

```bash
mp3fixer -n ~/Music
```

---

## Auto Confirm

Skip confirmation prompts:

```bash
mp3fixer -y ~/Music
```

---

## Verbose Logging

```bash
mp3fixer -v ~/Music
```

---

# CLI Options

| Option | Description              |
| ------ | ------------------------ |
| `-y`   | Auto confirm all renames |
| `-n`   | Dry run mode             |
| `-v`   | Verbose output           |
| `-h`   | Show help                |

---

# Example

## Before

```text
01_track.mp3
music_final_v2.mp3
unknown.mp3
```

## After

```text
Daft Punk - Harder Better Faster Stronger.mp3
Hans Zimmer - Time.mp3
Unknown Artist - Unknown Title.mp3
```

---

# Safe Filename Sanitization

Invalid filename characters are automatically replaced:

```text
/:*?"<>|
```

---

# Project Structure

```text
mp3fixer/
├── install.sh
├── mp3fixer.sh
└── README.md
```

# TODO :
  *  Bug with Directory : /
 
---
# Author
Yashar Razban

Made with Bash + ffprobe
