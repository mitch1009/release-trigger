# Release Trigger Action - Multi-Language Support Implementation

## Milestone: Add Rust and Python Support

This milestone tracks the implementation of Rust and Python language support in the Release Trigger Action, in addition to the existing JavaScript/TypeScript support.

---

## Overview

The current action is hardcoded for Node.js/pnpm projects using `standard-version`. We need to:
1. Add language detection
2. Support multiple version file formats
3. Support language-specific version bumping tools
4. Make setup steps conditional based on detected language

---

## Issue #1: Language Detection System

### Description
Implement automatic language detection to determine which language/framework the project uses.

### Tasks
- [ ] Add `language` input parameter (optional, auto-detect if not provided)
- [ ] Implement detection logic for:
  - **Rust**: Check for `Cargo.toml` file
  - **Python**: Check for `pyproject.toml`, `setup.py`, `setup.cfg`, or `__version__.py`
  - **JavaScript/TypeScript**: Check for `package.json` (existing)
- [ ] Add detection priority logic (handle monorepos with multiple languages)
- [ ] Add validation to ensure only one primary language is detected
- [ ] Output detected language for debugging

### Acceptance Criteria
- Action can detect Rust projects by presence of `Cargo.toml`
- Action can detect Python projects by presence of Python version files
- Action can detect JavaScript/TypeScript projects (existing behavior)
- Detection works in monorepo scenarios
- Clear error messages when language cannot be detected

---

## Issue #2: Rust Language Support

### Description
Add full support for Rust projects using Cargo for version management.

### Tasks

#### 2.1 Rust Setup and Tooling
- [ ] Add Rust toolchain setup step (using `actions-rs/toolchain@v1`)
- [ ] Install `cargo-release` or implement manual version bumping
- [ ] Add Cargo cache for faster builds
- [ ] Ensure Rust is only installed when Rust project is detected

#### 2.2 Rust Version File Handling
- [ ] Parse `Cargo.toml` to read current version
- [ ] Support version format: `version = "1.2.3"` in `[package]` section
- [ ] Support workspace projects with multiple `Cargo.toml` files
- [ ] Handle version in `Cargo.toml` with TOML parsing (not JSON)

#### 2.3 Rust Version Bumping
- [ ] Implement version bumping for Rust:
  - Option A: Use `cargo-release` crate (recommended)
  - Option B: Manual TOML parsing and version bumping
- [ ] Support semantic versioning (major, minor, patch)
- [ ] Update `Cargo.lock` after version bump (if needed)
- [ ] Support workspace versioning (bump all workspace members)

#### 2.4 Rust-Specific Configuration
- [ ] Add `rust_version_file_path` input (default: `Cargo.toml`)
- [ ] Add `rust_bump_script` input (optional, for custom scripts)
- [ ] Support `cargo-release` configuration in `Cargo.toml`
- [ ] Handle Rust-specific versioning conventions

### Acceptance Criteria
- Action can read version from `Cargo.toml`
- Action can bump version in `Cargo.toml` (major, minor, patch)
- Action works with Rust workspace projects
- Version bumping updates `Cargo.lock` appropriately
- GPG signing works with Rust releases
- Tags are created correctly for Rust projects

---

## Issue #3: Python Language Support

### Description
Add full support for Python projects with multiple version file format options.

### Tasks

#### 3.1 Python Setup and Tooling
- [ ] Add Python setup step (using `actions/setup-python@v5`)
- [ ] Install Python version bumping tools:
  - Option A: `bump2version` (recommended)
  - Option B: `setuptools-scm`
  - Option C: Manual version file editing
- [ ] Support multiple Python version managers (pip, poetry, pipenv)
- [ ] Add Python dependency caching
- [ ] Ensure Python is only installed when Python project is detected

#### 3.2 Python Version File Detection and Handling
- [ ] Detect and parse version from multiple sources:
  - `pyproject.toml` (PEP 621) - `[project] version = "1.2.3"`
  - `setup.py` - `version="1.2.3"` or `__version__`
  - `setup.cfg` - `[metadata] version = 1.2.3`
  - `__version__.py` or `version.py` - `__version__ = "1.2.3"`
  - `_version.py` (setuptools-scm style)
- [ ] Implement TOML parsing for `pyproject.toml`
- [ ] Implement Python file parsing for `__version__.py`
- [ ] Handle version in different formats (string, tuple, etc.)

#### 3.3 Python Version Bumping
- [ ] Implement version bumping for Python:
  - Use `bump2version` if `.bumpversion.cfg` exists
  - Use `setuptools-scm` if configured
  - Manual version file editing as fallback
- [ ] Support semantic versioning (major, minor, patch)
- [ ] Update all version references in the project
- [ ] Handle version in multiple files (if project uses multiple)

#### 3.4 Python-Specific Configuration
- [ ] Add `python_version_file_path` input (optional, auto-detect)
- [ ] Add `python_bump_script` input (optional, for custom scripts)
- [ ] Support `bump2version` configuration
- [ ] Support `setuptools-scm` configuration
- [ ] Handle Python package managers (pip, poetry, pipenv)

### Acceptance Criteria
- Action can detect Python projects
- Action can read version from common Python version files
- Action can bump version in Python projects (major, minor, patch)
- Action works with different Python project structures
- Version bumping updates all relevant version references
- GPG signing works with Python releases
- Tags are created correctly for Python projects

---

## Issue #4: Conditional Setup and Execution

### Description
Refactor the action to conditionally execute setup steps and version bumping based on detected language.

### Tasks
- [ ] Make Node.js setup conditional (only for JS/TS projects)
- [ ] Make pnpm setup conditional (only for JS/TS projects)
- [ ] Make Rust setup conditional (only for Rust projects)
- [ ] Make Python setup conditional (only for Python projects)
- [ ] Refactor version bumping step to be language-aware
- [ ] Refactor version reading to support multiple formats:
  - JSON (package.json)
  - TOML (Cargo.toml, pyproject.toml)
  - Python files (__version__.py)
- [ ] Add language-specific error handling
- [ ] Ensure backward compatibility with existing JS/TS workflows

### Acceptance Criteria
- Action only installs tools needed for detected language
- Version bumping works correctly for each language
- Version reading works for all supported formats
- Existing JavaScript/TypeScript workflows continue to work
- Clear error messages for unsupported languages

---

## Issue #5: Version File Path Handling

### Description
Improve version file path handling to support different file formats and locations.

### Tasks
- [ ] Make `version_file_path` input language-aware
- [ ] Auto-detect version file path if not provided:
  - Rust: `Cargo.toml` (or workspace root)
  - Python: Detect from project structure
  - JS/TS: `package.json` (existing)
- [ ] Support relative and absolute paths
- [ ] Validate version file exists and is readable
- [ ] Support workspace/monorepo scenarios with multiple version files

### Acceptance Criteria
- Version file path is auto-detected when not provided
- Action validates version file exists
- Works with custom version file paths
- Supports monorepo structures

---

## Issue #6: Version Bumping Scripts

### Description
Support language-specific version bumping scripts and tools.

### Tasks
- [ ] Refactor `bump_script` input to be language-aware
- [ ] Provide default bump scripts for each language:
  - Rust: `cargo-release` or custom script
  - Python: `bump2version` or custom script
  - JS/TS: `standard-version` (existing)
- [ ] Support custom bump scripts per language
- [ ] Add validation for bump script execution
- [ ] Handle bump script errors gracefully

### Acceptance Criteria
- Default bump scripts work for each language
- Custom bump scripts are supported
- Bump script errors are handled gracefully
- Version is correctly updated after bump script execution

---

## Issue #7: Testing and Documentation

### Description
Add comprehensive testing and update documentation for new language support.

### Tasks

#### 7.1 Testing
- [ ] Create test workflows for Rust projects
- [ ] Create test workflows for Python projects
- [ ] Test language detection logic
- [ ] Test version reading for all formats
- [ ] Test version bumping for all languages
- [ ] Test monorepo scenarios
- [ ] Test backward compatibility with JS/TS

#### 7.2 Documentation
- [ ] Update README.md with Rust usage examples
- [ ] Update README.md with Python usage examples
- [ ] Document version file formats for each language
- [ ] Document language detection behavior
- [ ] Add troubleshooting section
- [ ] Update prerequisites section
- [ ] Add examples for each language

### Acceptance Criteria
- Test workflows pass for all languages
- Documentation is complete and accurate
- Examples are provided for each language
- Troubleshooting guide is helpful

---

## Issue #8: Additional Language Support (Future)

### Description
Plan for additional language support to make the action truly multi-language.

### Tasks
- [ ] Design extensible architecture for adding new languages
- [ ] Document process for adding new language support
- [ ] Consider support for:
  - Java (pom.xml, build.gradle)
  - Go (go.mod)
  - Flutter (pubspec.yaml)
  - C# (.csproj, Directory.Build.props)
  - Ruby (Gemfile, version.rb)

### Acceptance Criteria
- Architecture supports easy addition of new languages
- Documentation explains how to add new languages
- Framework is extensible and maintainable

---

## Implementation Order

1. **Issue #1**: Language Detection System (Foundation)
2. **Issue #4**: Conditional Setup and Execution (Refactoring)
3. **Issue #2**: Rust Language Support (Implementation)
4. **Issue #3**: Python Language Support (Implementation)
5. **Issue #5**: Version File Path Handling (Enhancement)
6. **Issue #6**: Version Bumping Scripts (Enhancement)
7. **Issue #7**: Testing and Documentation (Quality Assurance)
8. **Issue #8**: Additional Language Support (Future)

---

## Notes

- All changes must maintain backward compatibility with existing JavaScript/TypeScript workflows
- Version bumping should follow semantic versioning (SemVer) for all languages
- GPG signing must work for all languages
- Tag creation must work consistently across all languages
- Changelog generation is language-agnostic and should continue to work

---

## Success Criteria

✅ Action can detect and support Rust projects  
✅ Action can detect and support Python projects  
✅ Action maintains full backward compatibility with JS/TS  
✅ All tests pass for all supported languages  
✅ Documentation is complete and accurate  
✅ Action is ready for production use with multi-language support

