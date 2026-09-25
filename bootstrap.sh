#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

# Disabled in this PoC-safe mode: do not update the repository during a demo.
# git pull origin main;

function doIt() {
	rsync --dry-run --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . ~ 2>&1 | sed 's/ (DRY RUN)//';
	source ~/.bash_profile;
	echo "Bootstrap completed successfully."
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
