# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Directory Structure

This is a multi-organization workspace, not a single project:

```
~/Projects/
├── jamesdh/           # Personal GitHub org
│   ├── dotfiles/      # Ansible-managed system configuration
│   └── ...
├── moltenbits/        # moltenbits GitHub org
│   └── ...
├── <org>/             # Other organization repos...
│   └── ...
└── Makefile           # Symlinked from dotfiles (see below)
```

Top-level directories are GitHub organizations. Subdirectories within them are repositories belonging to that organization.

## Makefile System

The root `Makefile` is symlinked from `jamesdh/dotfiles/roles/projects/files/projects.mak`. It provides a unified interface for interacting with all projects:

- `make help` - List all available targets
- `make <org>` - List targets for an organization (e.g., `make moltenbits`)
- `make <org>.<target>` - Run a target in an org's Makefile (e.g., `make proximal.start`)

Each organization directory may have its own Makefile, also symlinked from dotfiles.

## Dotfiles Architecture

The `jamesdh/dotfiles` repo uses Ansible to manage system configuration:

- **Playbooks**: `ansible.yml` (main), `homelab.yml` (remote)
- **Roles**: `roles/` contains modular configuration (osx, projects, ssh, base)
- **Vault files**: `*.vault.*` files are Ansible-encrypted secrets

### Key Dotfiles Commands

```bash
cd jamesdh/dotfiles
make bootstrap          # Initial setup
make install            # Run full Ansible playbook
make install.priority   # Install high-priority items only
make compare            # Dry-run diff against current state
make secrets.decrypt    # Decrypt vault files for editing
make secrets.encrypt    # Re-encrypt vault files
```

### Projects Role

The `roles/projects/` role manages:
- Git repository cloning and configuration
- Symlinked Makefiles, env files, and hooks
- SDK installations (Java, Gradle, Groovy, etc. via SDKMAN)
- `/etc/hosts` entries for local development

Configuration is in `roles/projects/defaults/main.yml` with secrets in vault files.
