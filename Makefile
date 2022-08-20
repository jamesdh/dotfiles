SHELL := $(shell which bash) -e
.DEFAULT_GOAL := help

include ./roles/projects/files/utils.mak

start: ## Opens all Dotfiles project tools
start: \
	start.iterm \
	start.tower \
	start.code

start.code: ## Opens dotfiles VSCode
start.code: code.start.jamesdh.dotfiles

start.iterm: ## Opens dotfiles iTerm
start.iterm: iterm.start.Dotfiles

start.tower: ## Opens dotfiles Tower
start.tower: tower.start.jamesdh.dotfiles

stop: ## Closes all Dotfiles project tools
stop: \
	stop.iterm \
	stop.tower \
	stop.code

stop.code: code.stop.dotfiles

stop.iterm: iterm.stop.Dotfiles

stop.tower: tower.stop.dotfiles

bootstrap: ## Verifies/installs necessary tools to support syncing dotfiles
bootstrap:
	@./bootstrap.sh ;\

login.appstore: 
	@while ! mas account > /dev/null 2>&1 ; do \
		read -p "Please signin to the Mac App Store before continuing..." ;\
	done

login.op: ## Login to 1Password
login.op:
	@FILE=~/.config/op/config ;\
	if [[ -f $$FILE ]]; then \
		ACCOUNT=$$(cat $$FILE | jq '.accounts | length') ;\
	fi ;\
	if [[ $$ACCOUNT -eq 0 ]]; then \
		if [[ ! -f ~/.ansible/dotfiles_vaultpass ]]; then \
			EMAIL=$$(bash -c 'read -p "1Password Account Email: " EMAIL; echo $$EMAIL') ;\
			SECRET=$$(bash -c 'read -p "1Password Account Secret: " SECRET; echo $$SECRET') ;\
		else \
			OUTPUT=$$(ansible localhost -m debug -a 'var="op.secret"' -e "@group_vars/all.yml") ;\
			SECRET=$$(echo $$OUTPUT | cut -d ">" -f 2 | jq -r '. | ."op.secret"') ;\
			OUTPUT=$$(ansible localhost -m debug -a 'var="op.email"' -e "@group_vars/all.yml") ;\
			EMAIL=$$(echo $$OUTPUT | cut -d ">" -f 2 | jq -r '. | ."op.email"') ;\
		fi ;\
		open -a "Authy Desktop" ;\
		SESSION=$$(op signin my $$EMAIL $$SECRET --raw) ;\
	elif [[ ! `op list users 2> /dev/null` ]]; then \
		SESSION=$$(op signin my --raw) ;\
	fi ;\
	if [[ -n "$$SESSION" ]]; then\
		printf 'eval $$(op signin my --session %s)\n' $$SESSION ;\
	else \
		printf 'eval $$(op signin my)\n' ;\
	fi ;\
	
login.all: login.op

install:
	@ echo ;\
	if op list users > /dev/null 2>&1 ; then \
		ansible-playbook --ask-become-pass --diff ansible.yml ;\
	else \
		echo 'Execute `eval $$(make login.op)` to login to 1Password before continuing' ;\
		echo ;\
		exit 1 ;\
	fi ;\
	
install.filtered: ## Install optionally filtering on given tags
install.filtered: list.tags 
	@ echo ;\
	if op list users > /dev/null 2>&1 ; then \
		INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
		EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
		ansible-playbook --ask-become-pass --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml ;\
	else \
		echo 'Execute `eval $$(make login.op)` to login to 1Password before continuing' ;\
		echo ;\
		exit 1 ;\
	fi ;\

compare: ## Diff checks the ansible playbooks against the current environment
compare: login.all
	ansible-playbook --ask-become-pass --check --diff ansible.yml

compare.filtered: ## Diff checks the specified playbook tags against the current environment
compare.filtered: login.all list.tags 
	@INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
	EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
	ansible-playbook --ask-become-pass --check --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml

list.tags: ## Lists all playbook tags that could be filtered upon
	@TAGS=$$(bash -c 'ansible-playbook --list-tags ansible.yml | grep "TASK TAGS"') ;\
	echo $$TAGS;\

list.tasks:
	ansible-playbook --list-tasks ansible.yml

secrets.create.%: ## Encrypts a NAME secret of VALUE, e.g. 'make secret NAME=pusher_secret VALUE=abc123'
	@ansible-vault encrypt_string --stdin-name '$*'
	
secrets.view.%:
	ansible localhost -m debug -a 'var="$*"' -e "@group_vars/all.yml"

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
