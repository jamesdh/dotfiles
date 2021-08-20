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

default: 
	@code $$(pwd)/ ;\

dotfiles.start: iterm.start.Dotfiles ## Opens all Dotfiles project tools
	@code $$(pwd)/jamesdh/dotfiles ;\
	gittower $$(pwd)/jamesdh/dotfiles/ ;\

dotfiles.stop: iterm.stop.Dotfiles ## Closes all Dotfiles project tools
	@./jamesdh/dotfiles/jxa/closeCode.jxa dotfiles ;\
	pkill -f 'Tower.app' || true ;\
	
tt.start: iterm.start.TeamTempo ## Opens all TeamTempo project tools
	@code $$(pwd)/moltenbits/teamtempo/front/ ;\
	idea $$(pwd)/moltenbits/teamtempo/back ;\
	gittower $$(pwd)/moltenbits/teamtempo/ ;\
	open postgresql://ttm:ttm@localhost/ttm?enviroment=local&name=TeamTempo ;\
	open -a 'Airmail' ;\
	open -a 'Slack' ;\

tt.stop: iterm.stop.TeamTempo ## Closes all TeamTempo project tools
	@pkill -f "idea $$(pwd)/moltenbits/teamtempo/back" || true ;\
	./jamesdh/dotfiles/jxa/closeCode.jxa teamtempo front ;\
	pkill TablePlus || true ;\
	pkill -f 'Tower.app' || true ;\
	pkill -f 'Slack.app/Contents/MacOS/Slack' || true ;\
	$(MAKE) -C moltenbits/teamtempo -f Makefile dev.stop || true ;\

proximal.start: iterm.start.Proximal ## Opens all Proximal project tools
	@sleep 1 ;\
	open -Fna 'Tower' --args $$(pwd)/proximal-health/platform; open -Fna 'Tower' --args $$(pwd)/proximal-health/reyes; open -Fna 'Tower' --args $$(pwd)/proximal-health/devops; \
	sleep 3 ;\
	code $$(pwd)/proximal-health ;\
	idea $$(pwd)/proximal-health/devops/base-image/keycloak/proximal-keycloak $$(pwd)/proximal-health/platform/admin-api $$(pwd)/proximal-health/platform/www-api ;\
	open -a 'Microsoft Teams' ;\
	open -a 'Microsoft Outlook' ;\

proximal.stop: iterm.stop.Proximal ## Closes all Proximal project tools
	@pkill -9 -f 'Tower.app' || true ;\
	./jamesdh/dotfiles/jxa/closeCode.jxa proximal-health ;\
	pkill -f "idea $$(pwd)/proximal-health" || true ;\
	pkill -f pgAdmin || true ;\
	pkill -f 'Outlook.app/Contents/MacOS/Microsoft Outlook' || true ;\
	$(MAKE) -C proximal-health/platform -f Makefile stop || true ;\
	
proximal.stop.all: ##proximal.stop
	@pkill -f 'Teams.app/Contents/MacOS/Teams' || true ;\

iterm.start.%: ## Opens iTerm with the given arrangement (Dotfiles, TeamTempo, or Proximal)
	@(nohup /Applications/iTerm.app/Contents/MacOS/iTerm2 -"Default Arrangement Name" "$*" -OpenArrangementAtStartup 1 >/dev/null 2>&1 &); 

iterm.stop.%: ## Closes iTerm sessions using the given arrangement
	@$(eval ITERM_PID:=$(shell ps -A -o pid,command | grep 'iTerm2 -Default Arrangement Name $*' | grep -v grep | head -n 1 | awk '{print $$1}'))
	@[[ -n $ITERM_PID ]] && kill -15 ${ITERM_PID} || true
