
COMMIT_MESSAGE = "updated version to "

.SILENT:
.PHONY: all commit tag check tag-r commit-r macos apk macos-sign-setup macos-build macos-sign-remove

commit: check commit-r tag-r

tag: check tag-r

all:
	echo "Run 'make commit' to commit and push changes"
	echo "Run 'make tag' to tag and push changes"
	echo "Run 'make macos' to build and sign for macOS"
	echo "Run 'make apk' to build for Android"

check:
	if ! command -v git; then
		echo 'git is not installed';
		exit 1;
	fi
	if ! command -v yq; then
		echo 'yq is not installed';
		exit 1;
	fi

commit-r:
	read -p 'Commit message: ' msg \
	COMMIT_MESSAGE = "$$msg & updated version to "
	git add --all

tag-r:
	CURRENT_BRANCH = $$(git branch --show-current)
	LAST_TAG = $$(git tag|tail -1)
	echo Last tag: $(LAST_TAG)
	read -p 'Next tag: ' tag \
	TAG = $$tag
	yq -i '.version = "$(TAG)"' pubspec.yaml
	git add pubspec.yaml
	git commit -m"$(COMMIT_MESSAGE) $(TAG)"
	git tag $(TAG)
	git push origin $(CURRENT_BRANCH) $(TAG)

macos: check macos-sign-setup macos-build macos-sign-remove

apk: check
	flutter build apk --release

macos-build:
	flutter build macos --release

macos-sign-setup:
	KEYCHAIN_NAME = temp_macos_build_$$(openssl rand -base64 8).keychain-db
	KEYCHAIN_PASSWORD = $$(openssl rand -base64 32)
	echo "Creating temporary keychain: $(KEYCHAIN_NAME)"
	security create-keychain -p "$(KEYCHAIN_PASSWORD)" "$(KEYCHAIN_NAME)"
	security set-keychain-settings -lut 21600 "$(KEYCHAIN_NAME)"
	security default-keychain -s "$(KEYCHAIN_NAME)"
	security unlock-keychain -p "$(KEYCHAIN_PASSWORD)" "$(KEYCHAIN_NAME)"
	security list-keychains -d user -s "$(KEYCHAIN_NAME)"

macos-sign-remove:
	echo "Deleting keychain $(KEYCHAIN_NAME)"
	security delete-keychain "$(KEYCHAIN_NAME)" || echo "Keychain not found or already deleted"

	