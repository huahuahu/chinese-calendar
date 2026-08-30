.DEFAULT_GOAL := help

.PHONY: help xcodeproj buildserver setup test format format-check lint ci build-apps seed-store validate-data-schemas

help:
	@echo "Common commands:"
	@echo "  make xcodeproj             Generate ChineseCalendar.xcodeproj"
	@echo "  make buildserver           Generate VS Code buildServer.json"
	@echo "  make setup                 Generate Xcode project and build server config"
	@echo "  make test                  Run tests on iOS Simulator"
	@echo "  make format                Format Swift sources"
	@echo "  make format-check          Check Swift formatting"
	@echo "  make lint                  Run SwiftLint"
	@echo "  make ci                    Run local CI checks"
	@echo "  make build-apps            Build the iOS app target"
	@echo "  make seed-store            Build/update the versioned SwiftData seed store artifact"
	@echo "  make validate-data-schemas Validate generated data schema artifacts"

xcodeproj:
	./Scripts/generate_xcodeproj.sh

buildserver:
	./Scripts/generate_buildserver_config.sh

setup: xcodeproj buildserver

test:
	./Scripts/test.sh

format:
	./Scripts/format.sh

format-check:
	./Scripts/format.sh --check

lint:
	./Scripts/lint.sh

ci:
	./Scripts/ci.sh

build-apps:
	./Scripts/build_apps.sh

seed-store:
	./Scripts/BuildChineseCalendarSeedStore/generate_seed_store_if_needed.sh

validate-data-schemas:
	./Scripts/validate_data_schemas.sh
