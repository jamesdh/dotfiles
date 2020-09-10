.DEFAULT_GOAL := help

help: ## This help screen
	@IFS=$$'\n' ; \
  help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
  printf "%-30s %s\n" "Target" "Function" ; \
  printf "%-30s %s\n" "------" "----" ; \
  for help_line in $${help_lines[@]}; do \
      IFS=$$':' ; \
      help_split=($$help_line) ; \
      help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
      help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
      printf '\033[36m'; \
      printf "%-30s %s" $$help_command ; \
      printf '\033[0m'; \
      printf "%s\n" $$help_info; \
  done

diff:
	ansible-playbook --ask-become-pass --diff ansible.yml

bootstrap:
	@./bootstrap.sh ;\
	source ~/.bash_profile

login.appstore: 
	@while ! mas account > /dev/null 2>&1 ; do \
		read -p "Please signin to the Mac App Store before continuing..." ;\
	done

login.op:
	@FILE=~/.op/config ;\
	ACCOUNTS=0 ;\
	if [ -f "$$FILE" ]; then \
		ACCOUNT=$$(cat $$FILE | jq '.accounts | length') ;\
	fi ;\
	if [ "$$ACCOUNT" -eq "0" ]; then \
		OUTPUT=$$(ansible localhost -m debug -a 'var="op.secret"' -e "@group_vars/all.yml") ;\
		SECRET=$$(echo $$OUTPUT | cut -d ">" -f 2 | jq -r '. | ."op.secret"') ;\
		OUTPUT=$$(ansible localhost -m debug -a 'var="op.email"' -e "@group_vars/all.yml") ;\
		EMAIL=$$(echo $$OUTPUT | cut -d ">" -f 2 | jq -r '. | ."op.email"') ;\
		op signin my $$EMAIL $$SECRET ;\
	fi

login.all: login.appstore login.op

install: login.all
	ansible-playbook --ask-become-pass --diff ansible.yml

install.filtered: login.all list.tags 
	@INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
	EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
	ansible-playbook --ask-become-pass --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml

compare: login.all
	ansible-playbook --ask-become-pass --check --diff ansible.yml

compare.filtered: login.all list.tags 
	@INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
	EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
	ansible-playbook --ask-become-pass --check --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml

list.tags: 
	@TAGS=$$(bash -c 'ansible-playbook --list-tags ansible.yml | grep "TASK TAGS"') ;\
	echo $$TAGS;\

list.tasks:
	ansible-playbook --list-tasks ansible.yml

secret: ## Encrypts a NAME secret of VALUE, e.g. 'make secret NAME=pusher_secret VALUE=abc123'
	ansible-vault encrypt_string --name '$(NAME)' '$(VALUE)'

secret.view:
	ansible localhost -m debug -a 'var="$(NAME)"' -e "@group_vars/all.yml"