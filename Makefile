# Comandos de desarrollo para el proyecto ft_irc (C++98).
# Ver AgentGuide.md, seccion 7.
#
#   make build             Configurar y compilar el proyecto
#   make test              Ejecutar todas las pruebas
#   make test-unit         Ejecutar pruebas unitarias
#   make test-integration  Ejecutar pruebas de integracion
#   make valgrind          Ejecutar pruebas con Valgrind
#   make sanitize          Compilar y ejecutar pruebas con sanitizadores
#   make clean             Eliminar directorios de build generados
#   make help              Mostrar esta ayuda

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
	@echo "Comandos disponibles:"
	@echo "  make build             Configurar y compilar el proyecto"
	@echo "  make test              Ejecutar todas las pruebas"
	@echo "  make test-unit         Ejecutar pruebas unitarias"
	@echo "  make test-integration  Ejecutar pruebas de integracion"
	@echo "  make valgrind          Ejecutar pruebas con Valgrind"
	@echo "  make sanitize          Compilar y ejecutar pruebas con sanitizadores"
	@echo "  make clean             Eliminar directorios de build generados"
	@echo "  make help              Mostrar esta ayuda"
