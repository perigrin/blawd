# BlawdNexus Test Suite

This directory contains the comprehensive test suite for BlawdNexus, ensuring all components work correctly and reliably.

## Test Files Overview

| File | Description | Coverage |
|------|-------------|----------|
| `00-load.t` | Basic module loading test | All modules are verified to load correctly |
| `01-index.t` | Tests for index classes | Base Index, Archive Index, Tag Index, Semantic Index |
| `02-template.t` | Tests for template system | Template loading, parsing, caching, and error handling |
| `03-renderer.t` | Tests for HTML renderer | Entry rendering, index rendering, fragment handling |
| `04-builder.t` | Tests for builder system | Configuration loading, entry discovery, site building |
| `05-plugin.t` | Tests for plugin system | Basic plugin functionality, lifecycle hooks |
| `06-entry.t` | Tests for entry classes | Base Entry, MultiMarkdown Entry, front matter parsing |
| `07-cli.t` | Tests for CLI | Command registration, option handling, command execution |
| `08-renderers.t` | Tests for additional renderers | RSS, Atom, and JSON renderers |
| `09-app.t` | Tests for main application | Site building, rendering, plugins application |
| `10-filewatcher.t` | Tests for file watching | File change detection, event handling |
| `11-util.t` | Tests for utility functions | Slugify function |
| `99-integration.t` | End-to-end integration tests | Complete site building and rendering |

## Test Coverage

The test suite aims to provide comprehensive coverage of all BlawdNexus components:

- **Entry System**: Full coverage of entry classes, front matter parsing, and rendering
- **Index System**: Full coverage of all index types and their specific functionality
- **Rendering System**: Coverage of all renderers (HTML, RSS, Atom, JSON)
- **Template System**: Coverage of template loading, parsing, and error handling
- **Builder System**: Coverage of configuration loading, entry discovery, and site building
- **Plugin System**: Coverage of plugin lifecycle and application
- **CLI System**: Coverage of command registration, option handling, and execution
- **File Watching**: Coverage of file change detection and event handling
- **Utilities**: Coverage of helper functions

## Running Tests

To run the entire test suite:

```bash
prove -lr t
```

To run a specific test file:

```bash
prove -v t/01-index.t
```

To run integration tests (disabled by default):

```bash
TEST_INTEGRATION=1 prove -v t/99-integration.t
```

## Test Dependencies

The test suite relies on the following modules:

- `Test2::V0`: Modern testing framework
- `Path::Tiny`: File path handling
- `Capture::Tiny`: For capturing stdout/stderr
- `YAML::XS`: For configuration handling
- `XML::Simple`: For XML validation
- `JSON::PP`: For JSON validation

Make sure these are installed before running the tests:

```bash
cpanm Test2::V0 Path::Tiny DateTime Capture::Tiny YAML::XS XML::Simple JSON::PP
```
