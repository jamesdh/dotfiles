SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: iterm

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

default: ## Opens VSCode for this directory
default: 
	@code $$(pwd)/

stop: ## Stops all projects
stop: \
	stop.proximal \
	stop.teamtempo \
	stop.dotfiles

start.dotfiles: ## Opens all Dotfiles project tools
start.dotfiles: \
	iterm.start.Dotfiles \
	tower.start.jamesdh.dotfiles \
	code.start.jamesdh.dotfiles

stop.dotfiles: ## Closes all Dotfiles project tools
stop.dotfiles: \
	iterm.stop.Dotfiles \
	tower.stop.dotfiles \
	code.stop.dotfiles 
	
start.teamtempo: ## Opens all TeamTempo project tools
start.teamtempo: \
	iterm.start.TeamTempo \
	tower.start.moltenbits.teamtempo \
	idea.start.moltenbits.teamtempo.back \
	code.start.moltenbits.teamtempo.front 
	@open -a 'Airmail' 
	@open postgresql://ttm:ttm@localhost/ttm?enviroment=local&name=TeamTempo 
	@open -a 'Slack' 

stop.teamtempo: ## Closes all TeamTempo project tools
stop.teamtempo: \
	iterm.stop.TeamTempo \
	tower.stop.teamtempo \
	code.stop.teamtempo \
	code.stop.front \
	idea.stop.teamtempo
	@pkill TablePlus || true 
	@$(MAKE) -C moltenbits/teamtempo -f Makefile dev.stop || true 

stop.teamtempo.all: ## Closes all TeamTempo tools including comms apps
stop.teamtempo.all: \
	stop.teamtempo
	@pkill -f 'Slack.app/Contents/MacOS/Slack' || true 
	@pkill -f '/Applications/Airmail.app/Contents/MacOS/Airmail' || true 

start.proximal: ## Opens all Proximal project tools
start.proximal: \
	start.proximal.iterm \
	start.proximal.tower \
	start.proximal.idea \
	start.proximal.comms

start.proximal.iterm: \
	iterm.start.Proximal 

start.proximal.tower: \
	tower.start.proximal-health.platform+proximal-health.reyes+proximal-health.devops 

start.proximal.idea: \
	idea.start.proximal-health.devops.base-image.keycloak.proximal-keycloak+proximal-health.platform.admin-api+proximal-health.platform.www-api 

start.proximal.code: \
	code.start.proximal-health.platform.admin-ui \
	code.start.proximal-health.platform.www-ui

start.proximal.comms: 
	@open -a 'Microsoft Teams' 
	@open -a 'Microsoft Outlook' 

stop.proximal: ## Closes all Proximal project tools
stop.proximal: \
	iterm.stop.Proximal \
	tower.stop.devops \
	tower.stop.platform \
	tower.stop.reyes \
	code.stop.proximal-health \
	code.stop.www-ui \
	code.stop.admin-ui \
	idea.stop.www-api \
	idea.stop.admin-api \
	idea.stop.keycloak 
	@pkill -f 'Outlook.app/Contents/MacOS/Microsoft Outlook' || true 
	@$(MAKE) -C proximal-health/platform -f Makefile stop || true 

stop.proximal.all: ## Closes all Proximal tools including comms apps
stop.proximal.all: \
	stop.proximal
	@pkill -f 'Teams.app/Contents/MacOS/Teams' || true 

iterm.start.%:
	@(nohup /Applications/iTerm.app/Contents/MacOS/iTerm2 -"Default Arrangement Name" "$*" -OpenArrangementAtStartup 1 >/dev/null 2>&1 &)

iterm.stop.%: 
	@$(eval ITERM_PID:=$(shell ps -A -o pid,command | grep 'iTerm2 -Default Arrangement Name $*' | grep -v grep | head -n 1 | awk '{print $$1}'))
	@[[ "${ITERM_PID}" ]] && kill -15 ${ITERM_PID} || true

tower.start.%: 
	@sleep 1
	@open -Fna 'Tower' --args $$(pwd)/$(subst .,/,$(subst +,; open -Fna  'Tower' --args $$(pwd)/,$*))
	@sleep 3

tower.stop.%: 
	@pkill -f 'Tower\.app.*$*' || true 

idea.start.%: 
	@idea $$(pwd)/$(subst .,/,$(subst +, $$(pwd)/,$*))

idea.stop.%:
	@./jamesdh/dotfiles/jxa/closeIdea.jxa $* 

code.start.%: 
	@code $$(pwd)/$(subst .,/,$*)

code.stop.%:
	@./jamesdh/dotfiles/jxa/closeCode.jxa $* 
