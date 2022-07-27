include ./jamesdh/dotfiles/roles/projects/files/utils.mak

.PHONY: jamesdh moltenbits proximal-health

code: ## Opens VSCode for this directory
code: code.start..

stop: ## Stops all projects
stop: \
	proximal.stop \
	moltenbits.stop \
	dotfiles.stop

moltenbits: ## Lists available targets in the moltenbits project
	@$(MAKE) -C moltenbits --no-print-directory -f Makefile 
moltenbits.%: 
	@$(MAKE) -C moltenbits --no-print-directory -f Makefile $*
teamtempo: ## Lists available targets in the teamtempo project
	@$(MAKE) -C moltenbits/teamtempo --no-print-directory -f Makefile 
teamtempo.%: 
	@$(MAKE) -C moltenbits/teamtempo --no-print-directory -f Makefile $*
proximal: ## Lists available targets in the proximal project
	@$(MAKE) -C proximal-health --no-print-directory -f Makefile 
proximal.%: 
	@$(MAKE) -C proximal-health --no-print-directory -f Makefile $*
dotfiles: ## Lists available targets in the dotfiles project
	@$(MAKE) -C jamesdh/dotfiles --no-print-directory -f Makefile 
dotfiles.%: 
	@$(MAKE) -C jamesdh/dotfiles --no-print-directory -f Makefile $*