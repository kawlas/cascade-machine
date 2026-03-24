#!/usr/bin/env bash

detect_test_cmd() {
    if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
        printf 'npm test\n'
        return
    fi
    if [ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
        printf 'python -m pytest -x -q\n'
        return
    fi
    if [ -f "go.mod" ]; then
        printf 'go test ./...\n'
        return
    fi
    if [ -f "Cargo.toml" ]; then
        printf 'cargo test\n'
    fi
}

detect_lint_cmd() {
    if [ -f "package.json" ]; then
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || \
           grep -q '"eslint"' package.json 2>/dev/null; then
            printf 'npx eslint --fix . 2>/dev/null && npx prettier --write . 2>/dev/null\n'
            return
        fi
        [ -f "biome.json" ] && printf 'npx biome check --fix . 2>/dev/null\n'
        return
    fi
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if command -v ruff > /dev/null 2>&1; then
            printf 'ruff check --fix . 2>/dev/null && ruff format . 2>/dev/null\n'
            return
        fi
        if command -v black > /dev/null 2>&1; then
            printf 'black . 2>/dev/null && isort . 2>/dev/null\n'
        fi
        return
    fi
    if [ -f "Cargo.toml" ]; then
        printf 'cargo clippy --fix --allow-dirty 2>/dev/null && cargo fmt 2>/dev/null\n'
        return
    fi
    [ -f "go.mod" ] && printf 'gofmt -w . 2>/dev/null && go vet ./... 2>/dev/null\n'
}

git_baseline() {
    git rev-parse HEAD 2>/dev/null || printf 'no-git\n'
}
