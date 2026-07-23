PROJECT      := Trends.xcodeproj
SCHEME       := Trends
DERIVED_DATA := build
APP          := $(DERIVED_DATA)/Build/Products/Release/Trends.app

.PHONY: all generate build test lint install clean

all: test build

generate:
	@test -f project.local.yml || { \
		echo ""; \
		echo "❌ Нет project.local.yml с вашим Team ID (нужен для подписи —"; \
		echo "   без него настройки виджета не работают). Создайте файл:"; \
		echo ""; \
		echo "     settings:"; \
		echo "       base:"; \
		echo "         DEVELOPMENT_TEAM: <ваш Team ID>"; \
		echo ""; \
		echo "   Team ID: Xcode → Settings → Accounts → ваш Apple ID (вид: AB12CD34EF)."; \
		echo "   Подробности в README, раздел «Установка»."; \
		exit 1; }
	xcodegen generate

# Автоподпись из project.yml обязательна: без Team ID у AppIntents не
# работает конфигурация виджета (linkd не строит bundleIdentity).
# -allowProvisioningUpdates даёт Xcode выпустить сертификат при первой сборке.
build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(DERIVED_DATA) -allowProvisioningUpdates build

test:
	swift test --package-path TrendsKit

lint:
	swiftlint lint --strict

install: build
	rm -rf /Applications/Trends.app
	cp -R $(APP) /Applications/
	# Перепривязка размещённых виджетов к новому UUID расширения:
	# без этого виджет остаётся «зомби» со старым снимком UI.
	-killall chronod 2>/dev/null
	open /Applications/Trends.app

clean:
	rm -rf $(DERIVED_DATA) dist $(PROJECT) TrendsKit/.build
