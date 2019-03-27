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

check: login
	ansible-playbook --ask-become-pass --check --diff ansible.yml