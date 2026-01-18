# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an Ansible-based macOS configuration management repository. It automates system setup, application installation, and development environment provisioning using Ansible playbooks and roles.

## Commands

```bash
# Installation
make bootstrap              # Initial setup (Xcode, Homebrew, 1Password, Python venv)
make install                # Run full Ansible playbook
make install.priority       # Install high-priority items only (triggers logout)
make install.nonpriority    # Install lower-priority items
make install.filtered       # Interactive tag filtering
make install.homelab        # Run homelab playbook on remote server

# Validation
make compare                # Dry-run check against current state
make compare.filtered       # Filtered dry-run
make list.tags              # List available Ansible tags
make list.tasks             # List all tasks

# Secrets
make secrets.decrypt        # Decrypt all vault files for editing
make secrets.encrypt        # Re-encrypt vault files (only if changed)

# Homebrew
make apps.check             # Verify Brewfiles match installed apps
make apps.update            # Install/update from Brewfiles
make apps.diff              # Show apps not in Brewfiles
```

## Architecture

### Playbooks
- `ansible.yml` - Main playbook for localhost (macOS)
- `homelab.yml` - Remote playbook for Ubuntu server (Docker/Portainer/Home Assistant)

### Roles
- **base** - Shell environment (zsh, Oh My Zsh, dotfiles in `roles/base/files/dotfiles/`)
- **ssh** - SSH config and 1Password key integration
- **osx** - macOS system preferences, Homebrew apps, per-app configuration
- **projects** - Git repos, SDKs (SDKMAN), Makefiles, /etc/hosts entries

### Tagging
- `priority` - Essential items for initial setup (runs with logout after)
- `nonpriority` - Optional items for later
- Role/feature tags: `osx`, `ssh`, `base`, `projects`, `apps`, `iterm`, `tower`, `code`, etc.

## Secrets

Vault files use pattern `*.vault.*` and are encrypted with Ansible Vault. Password is stored in `~/.ansible/dotfiles_vaultpass` (retrieved from 1Password during bootstrap).

**Workflow:**
1. `make secrets.decrypt` - Creates plaintext files and `.enc` backups
2. Edit the plaintext files
3. `make secrets.encrypt` - Re-encrypts only if content changed

Vault files are in:
- `roles/*/vars/main/*.vault.yml` - Ansible variables
- `roles/*/files/*.vault.*` - Env files and Makefiles

## Key Locations

| Purpose | Location |
|---------|----------|
| macOS defaults | `roles/osx/defaults/main.yml` |
| Brewfiles | `roles/osx/files/Brewfile*` |
| Shell dotfiles | `roles/base/files/dotfiles/` |
| Per-app config tasks | `roles/osx/tasks/per_app/` |
| Custom Ansible module | `library/osx_defaults.py` |
| Projects config | `roles/projects/defaults/main.yml` |

## Conventions

- Tasks use `when:` clauses for conditional execution based on file/package existence
- 1Password lookups (`community.general.onepassword`) retrieve licenses and credentials
- `check_mode: no` on tasks that must run even in dry-run mode
- Brewfiles split by priority: `Brewfile.bootstrap`, `Brewfile.priority`, `Brewfile.privileged`, `Brewfile.nonpriority`, `Brewfile.fonts`
