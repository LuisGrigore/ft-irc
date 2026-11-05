# Development commands for the ft_irc project (C++98).
# See AgentGuide.md, section 7.
#
#   make build             Configure and compile the project
#   make test              Run all tests
#   make test-unit         Run unit tests
#   make test-integration  Run integration tests
#   make valgrind          Run tests with Valgrind
#   make sanitize          Compile and run tests with sanitizers
#   make clean             Remove generated build directories
#   make help              Show this help

.PHONY: build test test-unit test-integration valgrind sanitize clean help

BUILD_DIR ?= build
SANITIZE_DIR ?= build-asan

build:
	cmake -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Debug
	cmake --build $(BUILD_DIR)

test: build
	ctest --test-dir $(BUILD_DIR) --output-on-failure

test-unit: build
	ctest --test-dir $(BUILD_DIR) -L unit --output-on-failure

test-integration: build
	ctest --test-dir $(BUILD_DIR) -L integration --output-on-failure

valgrind: build
	valgrind \
		--leak-check=full \
		--show-leak-kinds=all \
		--errors-for-leak-kinds=definite,indirect \
		--error-exitcode=1 \
		$(BUILD_DIR)/tests/unit_tests
	valgrind \
		--leak-check=full \
		--show-leak-kinds=all \
		--errors-for-leak-kinds=definite,indirect \
		--error-exitcode=1 \
		$(BUILD_DIR)/tests/integration_tests

sanitize:
	cmake -S . -B $(SANITIZE_DIR) -DCMAKE_BUILD_TYPE=Debug -DENABLE_SANITIZERS=ON
	cmake --build $(SANITIZE_DIR)
	ctest --test-dir $(SANITIZE_DIR) --output-on-failure

clean:
	rm -rf $(BUILD_DIR) $(SANITIZE_DIR)

help:
	@echo "Available commands:"
	@echo "  make build             Configure and compile the project"
	@echo "  make test              Run all tests"
	@echo "  make test-unit         Run unit tests"
	@echo "  make test-integration  Run integration tests"
	@echo "  make valgrind          Run tests with Valgrind"
	@echo "  make sanitize          Compile and run tests with sanitizers"
	@echo "  make clean             Remove generated build directories"
	@echo "  make help              Show this help"
