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
	./setup.sh

login: 
	@if ! lpass status -q ; then \
		LP_USER=$$(bash -c 'read -p "LastPass Username: " pwd; echo $$pwd') ;\
		lpass login $$LP_USER ;\
	fi

install: login
	ansible-playbook --ask-become-pass --diff ansible.yml

install.filtered: login list.tags 
	@INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
	EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
	ansible-playbook --ask-become-pass --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml

compare: login
	ansible-playbook --ask-become-pass --check --diff ansible.yml

compare.filtered: login list.tags 
	@INCTAGS=$$(bash -c 'read -p "Included tags? (default is all): " tags; tags=$${tags:-all}; echo $$tags') ;\
	EXCTAGS=$$(bash -c 'read -p "Excluded tags? (default is none): " tags; echo $$tags') ;\
	ansible-playbook --ask-become-pass --check --diff --tags=$$INCTAGS --skip-tags=$$EXCTAGS ansible.yml

list.tags: 
	@TAGS=$$(bash -c 'ansible-playbook --list-tags ansible.yml | grep "TASK TAGS"') ;\
	echo $$TAGS;\

list.tasks:
	ansible-playbook --list-tasks ansible.yml