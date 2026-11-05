# AgentGuide.md

# Repository Initialization Guide

## 1. Objective

Initialize this repository as a clean, simple and easy-to-contribute C++98 project.

The goal is to leave the repository ready for development, including:

- A clean and understandable project structure.
- C++98 compilation enforced at build level.
- Unit tests.
- Integration tests.
- Simple commands to build and execute tests.
- Memory leak detection.
- Static analysis and compiler warnings.
- A lightweight CI pipeline.
- A simple Git branching strategy.
- Clear documentation for contributors.

**Simplicity is the highest priority.**

Do not introduce unnecessary abstractions, dependencies, scripts or configuration layers.

A new contributor should be able to clone the repository, build the project and run all tests with minimal effort.

---

## 2. Technical decisions

Use the following tools:

| Area | Tool |
|---|---|
| Language | C++98 |
| Build system | CMake |
| Test runner | CTest |
| Unit/integration testing | CppUTest |
| Compiler | GCC / Clang |
| Memory checking | Valgrind |
| Additional memory checking | AddressSanitizer + UndefinedBehaviorSanitizer |
| CI | GitHub Actions |
| Version control | Git |

### C++ standard

C++98 is mandatory.

Configure CMake to enforce:

- C++98.
- No compiler-specific language extensions.
- No accidental use of C++11 or later features.

Use:

```cmake
set(CMAKE_CXX_STANDARD 98)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
```

Do not silently fall back to a newer C++ standard.

### Testing framework

Use CppUTest, provided the selected version supports the required C++98 toolchain.

Keep test dependencies isolated from production code.

Do not create a custom testing framework.

Tests must be executable independently and through CTest.

---

## 3. Repository structure

Create the following structure:

```text
.
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── cmake/
│   └── (only if strictly necessary)
│
├── include/
│   └── (public headers)
│
├── src/
│   └── (production source files)
│
├── tests/
│   ├── unit/
│   │   └── (unit tests)
│   │
│   ├── integration/
│   │   └── (integration tests)
│   │
│   └── CMakeLists.txt
│
├── scripts/
│   └── (only if strictly necessary)
│
├── build/
│   └── (generated files, never committed)
│
├── CMakeLists.txt
├── Makefile
├── .gitignore
├── .clang-format
├── .clang-tidy (only if compatible and useful)
├── README.md
├── CONTRIBUTING.md
└── AgentGuide.md
```

Do not create empty abstraction layers or unnecessary directories.

The `include/` and `src/` directories must remain independent of the testing framework.

---

## 4. Build system

Configure CMake with the following targets:

- Production library or executable, depending on the project.
- Unit tests.
- Integration tests.

If the repository does not contain production code yet, create a minimal compilable example that demonstrates the build and testing infrastructure.

Use a single root `CMakeLists.txt` and a separate `tests/CMakeLists.txt`.

Enable CTest:

```cmake
enable_testing()
```

Organize tests using CTest labels:

- `unit`
- `integration`

This must allow contributors to execute each category independently.

Example:

```bash
ctest --test-dir build -L unit --output-on-failure
ctest --test-dir build -L integration --output-on-failure
```

### Compiler warnings

Enable reasonable warnings:

```text
-Wall
-Wextra
-Wpedantic
```

Do not use `-Werror` by default.

Warnings should be visible without making development unnecessarily restrictive.

---

## 5. Testing architecture

Tests must be separated into two categories.

### 5.1 Unit tests

Location:

```text
tests/unit/
```

Purpose:

Test individual classes and functions independently.

Requirements:

- Avoid external dependencies.
- Avoid filesystem or network operations unless essential.
- Keep tests deterministic.
- Test expected behavior and error conditions.
- Use descriptive test names.
- Keep each test focused on one behavior.

Example naming:

```text
test_user.cpp
test_parser.cpp
test_memory_manager.cpp
```

### 5.2 Integration tests

Location:

```text
tests/integration/
```

Purpose:

Validate interactions between multiple components.

Examples:

- Reading and writing files.
- Communication between modules.
- End-to-end workflows.
- Interaction with external resources, if applicable.

Requirements:

- Keep tests independent.
- Clean up temporary resources.
- Do not depend on execution order.
- Do not modify production data.
- Use temporary directories where necessary.

### 5.3 Test execution

The following commands must work:

```bash
# All tests
ctest --test-dir build --output-on-failure

# Unit tests
ctest --test-dir build -L unit --output-on-failure

# Integration tests
ctest --test-dir build -L integration --output-on-failure
```

Tests must return a non-zero exit code when they fail.

---

## 6. Memory management and leak detection

Memory checking is mandatory.

Provide two complementary mechanisms.

### 6.1 Valgrind

Valgrind must be the primary memory checking tool.

Provide a CMake option or documented workflow to execute tests with Valgrind.

The configuration must:

- Enable full leak checking.
- Show all leak kinds.
- Treat definite and indirect leaks as errors.
- Return a non-zero exit code when memory errors are detected.
- Avoid suppressions unless they are strictly necessary and documented.

Suggested command:

```bash
valgrind \
  --leak-check=full \
  --show-leak-kinds=all \
  --errors-for-leak-kinds=definite,indirect \
  --error-exitcode=1 \
  ./build/tests/unit_tests
```

Adapt executable paths to the actual generated targets.

Ensure that integration tests can also be executed under Valgrind.

Do not run Valgrind recursively over CTest itself. Run it against the actual test executables or use a dedicated CTest configuration.

### 6.2 Sanitizers

Provide an optional CMake option:

```text
ENABLE_SANITIZERS
```

When enabled, use:

```text
-fsanitize=address,undefined
-fno-omit-frame-pointer
```

Apply the required compile and link flags to the relevant targets.

Use sanitizers only when supported by the selected compiler.

Document how to enable them:

```bash
cmake -S . -B build-asan \
  -DCMAKE_BUILD_TYPE=Debug \
  -DENABLE_SANITIZERS=ON

cmake --build build-asan

ctest --test-dir build-asan --output-on-failure
```

Keep sanitizer builds separate from normal builds.

Do not enable sanitizers in production builds by default.

---

## 7. Developer commands

Contributors should not need to remember complicated CMake commands.

Create a simple Makefile wrapping the common workflows.

The following commands must be available:

```bash
make build
make test
make test-unit
make test-integration
make valgrind
make sanitize
make clean
make help
```

Expected behavior:

| Command | Description |
|---|---|
| `make build` | Configure and compile the project |
| `make test` | Execute all tests |
| `make test-unit` | Execute unit tests |
| `make test-integration` | Execute integration tests |
| `make valgrind` | Execute tests with Valgrind |
| `make sanitize` | Build and execute tests with sanitizers |
| `make clean` | Remove generated build directories |
| `make help` | Display available commands |

Use sensible defaults.

The default build directory should be `build/`.

The sanitizer build directory should be `build-asan/`.

Do not introduce a complicated shell scripting system to achieve this.

---

## 8. Continuous Integration

Use GitHub Actions.

Create:

```text
.github/workflows/ci.yml
```

The CI pipeline must be simple and fast.

### 8.1 When to execute

Run CI on:

- Push to `main`.
- Push to `develop`.
- Pull requests targeting `main`.
- Pull requests targeting `develop`.

### 8.2 Pipeline jobs

Implement the following checks.

**Job 1: Build and tests**

1. Checkout repository.
2. Install dependencies.
3. Configure CMake.
4. Build the project.
5. Execute unit tests.
6. Execute integration tests.

**Job 2: Memory checks**

1. Checkout repository.
2. Install dependencies.
3. Build the project in Debug mode.
4. Execute tests with Valgrind.

**Job 3: Sanitizers**

1. Checkout repository.
2. Install dependencies.
3. Configure with sanitizers enabled.
4. Build the project.
5. Execute all tests.

Avoid unnecessary matrices, multiple operating systems or complex deployment stages.

Use one Linux environment initially.

Use Ubuntu and a compatible GCC toolchain.

Pin GitHub Actions to stable versions and avoid unnecessary third-party actions.

### 8.3 CI requirements

The pipeline must fail if:

- The project does not compile.
- Any unit test fails.
- Any integration test fails.
- Valgrind detects relevant memory errors.
- Sanitizers report memory errors or undefined behavior.

Do not configure CI to ignore test failures.

Do not add deployment stages: this project only needs continuous integration and validation at this stage.

---

## 9. Git workflow

Use the following branching strategy:

```text
main
  |
  └── develop
        |
        ├── feature/feature-name
        ├── feature/another-feature
        ├── fix/bug-description
        └── refactor/refactor-description
```

### main

- Always stable.
- Contains validated code.
- Only receives changes from `develop` through pull requests.
- CI must pass before merging.

### develop

- Integration branch.
- Receives completed features.
- CI must pass before merging.

### feature branches

Create one branch per feature:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/feature-name
```

When finished:

1. Push the branch.
2. Create a pull request targeting `develop`.
3. Ensure CI passes.
4. Review the changes.
5. Merge into `develop`.
6. Delete the feature branch.

Use the same approach for bug fixes and refactoring.

### Releases

When a version is ready:

1. Create a pull request from `develop` to `main`.
2. Ensure all checks pass.
3. Merge.
4. Create a version tag.

Avoid introducing additional branch types such as `release/*` or `hotfix/*` unless the project genuinely needs them.

### Branch protection

Document the recommended GitHub branch protection settings:

- Require pull requests.
- Require successful CI checks.
- Prevent direct pushes to `main`.
- Prevent force pushes to protected branches.

Apply equivalent protections to `develop` where appropriate.

Do not attempt to configure remote repository permissions without explicit authorization.

---

## 10. Code formatting and quality

Add a minimal `.clang-format`.

Use a consistent and readable style.

Prefer:

- Clear naming.
- Small functions.
- Explicit ownership.
- Simple class responsibilities.
- RAII.
- Avoiding unnecessary dynamic memory allocation.
- Avoiding raw owning pointers where possible.

Since this is a C++98 project, use the language facilities available in that standard.

In particular:

- Use `std::auto_ptr` only when legacy constraints require it; prefer explicit ownership designs and RAII alternatives compatible with C++98.
- Do not use `unique_ptr`, `shared_ptr`, lambdas or other C++11 features.
- Avoid unnecessary templates and metaprogramming.
- Avoid macros unless they provide a clear benefit.

Do not introduce a mandatory formatting or linting dependency into CI unless it is lightweight and straightforward to maintain.

---

## 11. Documentation

### README.md

Include:

1. Project description.
2. Requirements.
3. Dependencies.
4. Build instructions.
5. Test instructions.
6. Valgrind instructions.
7. Sanitizer instructions.
8. Repository structure.
9. Git workflow.

Keep it concise.

A new contributor should be able to get started by following the README alone.

### CONTRIBUTING.md

Explain:

- How to create a feature branch.
- How to build the project.
- How to add unit tests.
- How to add integration tests.
- How to run all checks.
- How to create a pull request.
- Basic coding conventions.

Keep the document practical rather than theoretical.

---

## 12. Git ignore

Configure `.gitignore` to exclude:

```text
build/
build-asan/
cmake-build-*/
CMakeFiles/
CMakeCache.txt
Testing/
*.o
*.a
*.so
*.out
compile_commands.json
```

Do not commit generated binaries or build artifacts.

---

## 13. Initial example

If the repository is empty, create a very small example implementation.

It must include:

- One production class or module.
- At least two unit tests.
- At least one integration test.
- A test that exercises dynamic memory allocation and deallocation.

The example should demonstrate how to extend the testing structure.

Do not create a large example application.

The purpose is to validate the infrastructure, not to define the project's architecture.

---

## 14. Validation checklist

Before finishing, the agent must verify all the following.

### Build

- [ ] CMake configures successfully.
- [ ] Project compiles with C++98.
- [ ] Compiler warnings are enabled.
- [ ] No C++11 features are used.

### Tests

- [ ] Unit tests compile and run.
- [ ] Integration tests compile and run.
- [ ] CTest discovers all tests.
- [ ] Tests can be executed independently.
- [ ] Failed tests produce a non-zero exit code.

### Memory

- [ ] Valgrind executes successfully.
- [ ] Memory errors cause a non-zero exit code.
- [ ] Sanitizer build works.
- [ ] Sanitizer tests execute successfully.

### Developer experience

- [ ] `make build` works.
- [ ] `make test` works.
- [ ] `make test-unit` works.
- [ ] `make test-integration` works.
- [ ] `make valgrind` works.
- [ ] `make sanitize` works.
- [ ] `make clean` works.
- [ ] `make help` works.

### CI

- [ ] GitHub Actions workflow exists.
- [ ] Build and tests are executed.
- [ ] Valgrind is executed.
- [ ] Sanitizers are executed.
- [ ] CI failures correctly block successful validation.

### Documentation

- [ ] README is complete.
- [ ] CONTRIBUTING is complete.
- [ ] Git workflow is documented.
- [ ] All developer commands are documented.

---

## 15. Final instructions to the agent

Follow these principles throughout the implementation:

1. **Keep it simple.** Prefer one straightforward solution over several layers of abstraction.
2. **Avoid overengineering.** Do not add tools just because they are commonly used in larger projects.
3. **Keep dependencies minimal.** Every dependency must have a clear purpose.
4. **Make everything reproducible.** A fresh clone should be sufficient to build and test the project.
5. **Do not silently skip checks.** Missing dependencies or unsupported tooling must be reported explicitly.
6. **Preserve C++98 compatibility.** This is a hard requirement.
7. **Document every non-obvious decision.** Do not document trivial implementation details.
8. **Do not invent project requirements.** If the repository already contains code, inspect it before modifying its architecture.
9. **Do not overwrite existing work.** Preserve existing source files, configuration and documentation unless changes are necessary.
10. **Verify before declaring completion.** Execute the actual build, tests, memory checks and developer commands.

### Final deliverable

At the end, provide a concise report containing:

- Files and directories created.
- Tools and dependencies introduced.
- Commands available to developers.
- Tests executed and their results.
- Valgrind and sanitizer results.
- CI workflow description.
- Any limitations or actions requiring manual configuration in GitHub.

The repository must be ready for a developer to start implementing features immediately.

**The final result should feel like a small, well-organized C++98 project, not an enterprise development platform.**