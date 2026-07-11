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

# Shared org-level clean: runs each immediate child repo's own clean via
# whichever mechanism it exposes — a Makefile clean target, a Justfile clean
# recipe, or a Gradle wrapper — and keeps going when one fails. Regardless of
# mechanism, also deletes every node_modules and .venv under each child
# (always regenerable, and a huge file-count burden on backups). NOTE: only
# dot-prefixed .venv — plain `venv` dirs (e.g. dotfiles' own ansible venv)
# are deliberately left alone. Use from an org Makefile as the body of its
# `clean` target: $(clean_child_repos)
define clean_child_repos
@for repo in */; do \
	if [ -f "$$repo/Makefile" ] && $(MAKE) -C "$$repo" -n clean >/dev/null 2>&1; then \
		echo "==> $$repo (make clean)"; \
		$(MAKE) -C "$$repo" --no-print-directory clean || echo "    clean failed in $$repo — continuing"; \
	elif [ -f "$$repo/Makefile" ] && head -1 "$$repo/Makefile" 2>/dev/null | grep -q ANSIBLE_VAULT; then \
		echo "!!  $$repo Makefile is vault-encrypted; run 'make secrets.decrypt' in jamesdh/dotfiles, then re-run"; \
	else \
		jf=""; \
		[ -f "$$repo/justfile" ] && jf="$$repo/justfile"; \
		[ -f "$$repo/Justfile" ] && jf="$$repo/Justfile"; \
		if [ -n "$$jf" ] && just --justfile "$$jf" --working-directory "$$repo" -n clean >/dev/null 2>&1; then \
			echo "==> $$repo (just clean)"; \
			just --justfile "$$jf" --working-directory "$$repo" clean || echo "    clean failed in $$repo — continuing"; \
		elif [ -x "$$repo/gradlew" ]; then \
			echo "==> $$repo (gradlew clean)"; \
			(cd "$$repo" && ./gradlew -q clean) || echo "    clean failed in $$repo — continuing"; \
		fi; \
	fi; \
	find "$$repo" -type d \( -name node_modules -o -name .venv \) -prune -print -exec rm -rf {} + | sed 's/^/    rm -rf /'; \
done
endef

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
