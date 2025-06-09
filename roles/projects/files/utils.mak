SHELL := $(shell which zsh) -e
.DEFAULT_GOAL := help
.PHONY: iterm idea code

help: SHELL := /usr/bin/env bash
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

iterm.start.%:
	@(nohup /Applications/iTerm.app/Contents/MacOS/iTerm2 -"Default Arrangement Name" "$*" -OpenArrangementAtStartup 1 >/dev/null 2>&1 &)

iterm.stop.%: 
	@$(eval ITERM_PID:=$(shell ps -A -o pid,command | grep 'iTerm2 -Default Arrangement Name $*' | grep -v grep | head -n 1 | awk '{print $$1}'))
	@[[ "${ITERM_PID}" ]] && kill ${ITERM_PID} || true

tower.start.%: 
	@sleep 1
	@open -Fna 'Tower' --args $${HOME}/Projects/$(subst .,/,$(subst +,; open -Fna  'Tower' --args $${HOME}/Projects/,$*))
	@sleep 3

tower.stop.%: 
	@pkill -f 'Tower\.app.*$*' || true 

idea.start.%: 
	@idea $${HOME}/Projects/$(subst .,/,$(subst +, $${HOME}/Projects/,$*))

idea.stop.%:
	@$${HOME}/Projects/jamesdh/dotfiles/jxa/closeIdea.jxa $* 

code.start.%: 
	@code $${HOME}/Projects/$(subst .,/,$*)

code.stop.%:
	@$${HOME}/Projects/jamesdh/dotfiles/jxa/closeCode.jxa $* 
