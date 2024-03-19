SHELL := $(shell which zsh) -e
.DEFAULT_GOAL := help

include ./roles/projects/files/utils.mak

open: ## Opens all Dotfiles project tools
open: \
	open.iterm \
	open.tower \
	open.code

open.code: ## Opens dotfiles VSCode
open.code: code.start.jamesdh.dotfiles

open.iterm: ## Opens dotfiles iTerm
open.iterm: iterm.start.Dotfiles

open.tower: ## Opens dotfiles Tower
open.tower: tower.start.jamesdh.dotfiles

close: ## Closes all Dotfiles project tools
close: \
	close.iterm \
	close.tower \
	close.code

close.code: code.stop.dotfiles

close.iterm: iterm.stop.Dotfiles

close.tower: tower.stop.dotfiles

bootstrap: ## Verifies/installs necessary tools to support syncing dotfiles
bootstrap:
	@./bootstrap.sh ;\

install: ## Install everything
install:
	@source venv/bin/activate && ansible-playbook --diff --skip-tags=privileged ansible.yml ;\

install.privileged: ## Install items requiring privilege escalation
install.privileged:
	@source venv/bin/activate && ansible-playbook --diff --tags=privileged ansible.yml ;\
	
install.filtered: ## Install optionally filtering on given tags
install.filtered: list.tags 
	@INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
	EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
	ansible-playbook --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml

compare: ## Diff checks the ansible playbooks against the current environment
compare:
	@ansible-playbook --check --diff ansible.yml

compare.filtered: ## Diff checks the specified playbook tags against the current environment
compare.filtered: list.tags 
	@INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
	EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
	ansible-playbook --check --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml

list.tags: ## Lists all playbook tags that could be filtered upon
	@TAGS=$$(bash -c 'ansible-playbook --list-tags ansible.yml | grep "TASK TAGS"') ;\
	echo $$TAGS

list.tasks:
	@ansible-playbook --list-tasks ansible.yml

secrets.create.%: ## Encrypts a NAME secret of VALUE, e.g. 'make secret NAME=pusher_secret VALUE=abc123'
	@ansible-vault encrypt_string --stdin-name '$*'
	
secrets.view.%:
	@ansible localhost -m debug -a 'var="$*"' -e "@group_vars/all.yml"

secrets.decrypt: ## Decrypts all secret files
secrets.decrypt: \
	vault.decrypt.roles.projects.vars.main \
	vault.decrypt.roles.ssh.vars.main \
	vault.decrypt.roles.projects.files

secrets.encrypt: ## Encrypts all secret files
secrets.encrypt: \
	vault.encrypt.roles.projects.vars.main \
	vault.encrypt.roles.ssh.vars.main \
	vault.encrypt.roles.projects.files

vault.encrypt.%:
	@for i in $$(find $(subst .,/,$*) -name '*.vault.*' ! -name '*.enc'); do \
		PREFORM=$$(ansible-vault view $$i.enc) ;\
		POSTFORM=$$(cat $$i) ;\
		if [ "$$PREFORM" == "$$POSTFORM" ]; then \
			echo "Restoring unchanged file $$i" ;\
			mv -f $$i.enc $$i ;\
		else \
			rm $$i.enc ;\
			echo "Encrypting $$i" ;\
			ansible-vault encrypt $$i ;\
		fi \
	done

vault.decrypt.%:
	@for i in $$(find $(subst .,/,$*) -name '*.vault.*' ! -name '*.enc'); do \
		echo "Decrypting $$i" ;\
		cp $$i $$i.enc ;\
		ansible-vault decrypt $$i ;\
	done
