# BlawdNexus

A modern static site generator with semantic indexing, built upon Blawd.

## Overview

BlawdNexus is a static site generator that builds upon the original Blawd
project but updated with modern Perl 5.40 features (especially the class
feature syntax) and enhanced with semantic indexing capabilities to provide
sophisticated "related content" linking.

## Key Features

- **Modern Perl** - Uses Perl 5.40's `feature class` syntax for clean,
  efficient code
- **Semantic Connections** - Leverages your existing Commonplace Book semantic
  database to provide intelligent content relationships
- **Zettlekasten Principles** - Supports atomic content with explicit
  connections
- **Extensibility** - Provides a flexible plugin architecture
- **Simple CLI** - Easy to use with the `bn` command-line tool

## Installation

```bash
# Clone the repository
git clone https://github.com/perigrin/blawd.git
cd blawd

# Install dependencies
cpanm --installdeps .

# Build and install
perl Build.PL
./Build
./Build test
./Build install
```

## Quick Start

```bash
# Create a new site
mkdir my-site
cd my-site
cp /path/to/blawd/examples/bn.yml .

# Create content directory
mkdir -p content

# Create a new entry
bn new --title "My First Post" --tags "perl,blawdnexus"

# Build the site
bn build

# Serve locally with auto-rebuild on changes
bn serve --watch
```

## Configuration

BlawdNexus uses a YAML-based configuration file (`bn.yml`) with sensible
defaults. Key settings include:

- Content sources (directories, git repositories)
- Output paths and options
- Semantic analysis settings
- Index definitions
- Rendering options
- Plugin configuration

## Integration with Semantic Database

BlawdNexus can integrate with your existing Commonplace Book semantic database:

```bash
# Index all entries in the semantic database
bn index-entries --all

# Index only new entries
bn index-entries --new
```

This allows for sophisticated "related content" functionality that suggests
semantically related entries based on content similarity.

## License

BlawdNexus is free software, licensed under the same terms as Perl itself.

## Author

Chris Prather
