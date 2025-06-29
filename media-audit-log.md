# Site Maintenance Tools Overview

**Generated:** 2025-06-29 01:22:54

## 📂 media-audit

A directory tree located at:
```
~/git/site-maint/media-audit/
```

Contains timestamped audits of each domain's media library:
- `unused-images.txt`: Full filenames of images deemed unused
- `deletion-preview.txt`: Dry-run preview of full filenames
- `deletion-preview-short.txt`: Dry-run preview with just filenames
- `deletion.log`: Records of deleted media (on wet runs)

Structure example:
```
media-audit/
  └── thejubileebible.org/
      ├── 2025-06-28-131233/
      │   └── unused-images.txt
      ├── latest -> 2025-06-28-131233/
      └── deletion.log
```

## 🧹 review-unused-media.sh

Located at: `~/git/site-maint/review-unused-media.sh`

**Purpose**: Interactively deletes unused media files from the remote server, with optional backup and dry-run support.

**Key Features**:
- Reads `unused-images.txt` for a given domain.
- Optional backup before deletion (`b` option).
- `--dry-run` support skips destructive actions and creates preview reports.
- SCP + SSH used to act remotely via InMotion SSH on port 2222.

**Typical Usage**:
```bash
~/git/site-maint/review-unused-media.sh thejubileebible.org --dry-run
```

## 📊 analyze-remote-media.sh

*(Coming soon or already maintained)*

- Expected to:
  - Connect to a remote WordPress site.
  - Analyze actual media files vs. those referenced in posts, pages, CSS, or widgets.
  - Generate `unused-images.txt` for local audit.

---

📝 **Reminder**: This file is for documentation only. Scripts should be executed with care — backups are encouraged before any deletion operation.