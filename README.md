![DOME](dome.svg)

---

# dome

**dome** is a minimalist dotfiles manager written in Bash that offers bidirectional syncing between your home directory and a Git-based dotfiles repository. It features Git integration, conflict detection/resolution (via custom hooks), pre/post-sync hooks, and an innovative distro-aware file mapping mechanism.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Syncing Mechanism](#syncing-mechanism)
- [Hooks and Customizations](#hooks-and-customizations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

`dome` is designed to be simple, robust, and unobtrusive. It allows you to keep your dotfiles (such as `.bashrc`, Neovim or tmux configurations) in a Git repository and mirror them with your home directory. With integrated distro-aware mapping, you can even manage variations in configuration (e.g. different aliases or paths) for different Linux distributions.

## Features

- **Bidirectional Syncing:** Keep your home and repository in perfect sync.
- **Git Integration:** Pull updates and push changes to your remote repository seamlessly.
- **Conflict Detection & Resolution:** Automatically detect conflicts and resolve them with your preferred merge tool via hooks.
- **Distro-Aware File Mapping:** Define distro-specific variants of your dotfiles using a simple YAML mapping.
- **Hooks:** Run custom commands before or after sync operations to automate tasks.
- **Force Home-based Repository:** The local dotfiles repository is always located under `$HOME`, regardless of the current working directory.
- **Backup Management:** Automatically create backups (organized by distro) during syncing—unless explicitly disabled.

## Requirements

- **Bash:** The script is written in Bash and intended for Unix-like systems.
- **git:** For managing your dotfiles repository.
- **yq:** For parsing YAML configuration files.
- **Merge Tool (Optional):** For conflict resolution (e.g., `meld`).

> [!NOTE]
> Although earlier versions referenced `rsync`, **dome** no longer depends on it.

## Installation

> [!NOTE]
> Ensure that `~/bin/` is in your **$PATH**

Run:
```bash
curl -fsSL https://raw.githubusercontent.com/vvhybe/dome/main/install.sh | bash
```

> [!TIP]
> To install the latest version of `dome`, or install a specific release (e.g. `v1.0.0`):

USE:
```bash
curl -fsSL https://raw.githubusercontent.com/vvhybe/dome/main/install.sh | bash -s -- --tag=v0.2.0
```

> [!TIP]
> You can suppress installation output with the flag --silent or -s.

## Initialize dome

Run the initialization command to set up the configuration and clone your `dotfiles` repository.
**Important**: When using a custom path (via `-p`), the repository will be forced to reside under `$HOME`. For example, running:

```bash
dome init -p my-dotfiles
```
will clone your repository into `$HOME/my-dotfiles`. If the specified folder already exists (and isn’t empty), dome will fall back to using the existing directory.

```bash
dome init
```

## Configuration

The main configuration file is located at [`~/.config/dome/config.yaml`](config.yaml). This file contains settings for:
Repository Settings

- repo: URL of your dotfiles Git repository.
- branch: The branch to use (e.g., main).
- local_path: The local path where your repository will be cloned. Note: This path is always forced to be under $HOME.

Distro Files Mapping

Define mappings to handle distro-specific configurations. For example:

```yaml
distro_files:
  .bashrc:
    arch: ".bashrc.arch"
    debian: ".bashrc.debian"

```

In this example, if you're running an Arch-based system, dome will use `.bashrc.arch` from your repository to update `~/.bashrc.`

## Hooks

Customize actions before and after syncing, pushing, and pulling:

```yaml
hooks:
  conflict_resolver: "meld"
  pre_sync: "echo 'Starting sync...'"
  post_sync: "notify-send 'Dotfiles synced!'"
  pre_pull: "echo 'Pulling updates...'"
  post_pull: "echo 'Updates pulled.'"
  pre_push: "echo 'Preparing to push...'"
  post_push: "echo 'Push complete.'"
```

## Usage

Run dome with the following commands:

- Initialize:

```bash
dome init
```

Sets up the configuration and clones the repository into a home-based folder.

- Bidirectional Sync:

```bash
dome sync
```

Syncs dotfiles between your repository and your home directory while applying distro-aware mappings.

  - Use `-s` for snapshot mode (files are copied instead of symlinked).
  - Use `-n` to disable backup creation.
  - Use `-v` for verbose output (detailed table output will list synced and backed up files).

- Pull Updates:

```bash
dome pull
```

Pulls the latest changes from the remote repository.

- Push Changes:

```bash
dome push
```

Pushes your local changes to the remote repository.

> [!NOTE]
> To push your changes, first commit them using Git. Then use dome push so that pre/post hooks are executed.

- Revert Backups:

```bash
dome revert
```

Restores dotfiles from the latest backup in your distro’s backup directory (located at `~/.config/dome/backups/<distro>/`). You may also specify a backup directory explicitly.

- Help & Version:

```bash
dome -h   # Show help message
dome -v   # Show version information
```

## Syncing Mechanism

dome maintains a true two-way mirror of your tracked dotfiles:

  1. Repo → Home Sync: 
  A “merged” view is created where distro-specific files (as defined in the `distro_files` mapping) are mapped to their common names before syncing to your home directory. If a file already exists at the destination, it is backed up (unless disabled) into a distro-organized backup folder (`$HOME/.config/dome/backups/<distro>/bak_<timestamp>_<RANDOM>`).

  2. Home → Repo Sync:
  Only files that are already tracked in the repository are updated. Changes to files in your home directory are synced back into their corresponding distro-specific files in the repository.

This mechanism ensures that only the dotfiles you want tracked are synchronized, keeping unrelated files safe.

## Hooks and Customizations

Customize your workflow using hooks:

  - **Conflict Resolver**: Specify your preferred merge tool (e.g., meld) for resolving conflicts.
  - **Pre-sync Hook**: Runs before the syncing process begins.
  - **Post-sync Hook**: Runs after syncing completes.
  - **Pre-pull Hook**: Runs before pulling changes from the remote.
  - **Post-pull Hook**: Runs immediately after changes are pulled.
  - **Pre-push Hook**: Runs before pushing changes (ensure changes are committed first).
  - **Post-push Hook**: Runs after pushing changes.

These hooks are defined in the YAML configuration and executed automatically during their respective operations.

## Troubleshooting

  - Repository Location:
    If you specify a custom path using `-p`, remember that the repository will be cloned under `$HOME` (e.g., `$HOME/my-dotfiles`). If the folder exists and is not empty, dome will fall back to that directory.

  - Backup Issues:
    When running `dome sync` with verbose output (`-v`), the tool displays the backup actions in a table. If no backups are created (for example, when using the `-n` flag), the backup column will remain empty.

  - Permission Issues:
    If you encounter permission errors during syncing, ensure that you have the appropriate read/write permissions and avoid running dome with sudo.

  - Dependency Issues:
    Verify that `git` and `yq` are installed and available in your `$PATH`.

## Contributing

Contributions to dome are welcome! Please fork the repository, create pull requests, and open issues if you have suggestions or encounter bugs. Follow the repository's contribution guidelines.

## License

dome is distributed under the [GPL-3.0 License](LICENSE).
