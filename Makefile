APP_FILES=$(shell find lib/assets/**/*.coffee)
TEST_FILES=$(shell find test/javascripts/*.coffee)

# For continuous rebuild of packages: `watch make .all`
.all: .app .test
	touch .all

# for now, exactly the same as .all
.pretestem: .all

.app: $(APP_FILES)
	browserify $(APP_FILES) -o lib/graft.js -t coffeeify

.test: $(TEST_FILES)
	browserify $(TEST_FILES) -o test/test_bundle.js -t coffeeify
