# BlawdNexus: A Modern Static Site Generator

## Project Overview

BlawdNexus is a modern static site generator that builds upon the original Blawd project but updated with Perl 5.40's class feature syntax and enhanced with semantic indexing to provide sophisticated "related content" linking capabilities. This design document outlines the architecture, components, and implementation plan for BlawdNexus.

## Core Principles

1. **Modern Perl** - Leverage Perl 5.40's `feature class` syntax to create a clean, efficient codebase
2. **Semantic Connections** - Implement advanced content relationship analysis beyond simple tags
3. **Zettlekasten Principles** - Support atomic content with explicit connections
4. **Extensibility** - Provide a flexible plugin architecture for easy customization
5. **Simplicity** - Maintain a straightforward API and configuration system

## System Architecture

### Core Components

1. **Content Management**
   - BlawdNexus::Entry - Represents individual content items
   - BlawdNexus::Index - Aggregates and organizes entries
   - BlawdNexus::Storage - Manages content sources and retrieval

2. **Rendering System**
   - BlawdNexus::Renderer - Transforms entries and indexes into output formats
   - BlawdNexus::Template - Controls visual presentation of content
   - BlawdNexus::Plugin - Extends functionality at various stages

3. **Semantic Engine**
   - BlawdNexus::Semantic::Analyzer - Processes content to extract meaning and relationships
   - BlawdNexus::Semantic::Index - Stores and queries content relationships
   - BlawdNexus::Plugin::RelatedContent - Suggests related content for entries

### Data Flow

1. **Content Discovery**
   - Find content files in configured locations
   - Load raw content

2. **Content Parsing**
   - Parse content into Entry objects
   - Extract metadata (title, date, author, tags)

3. **Semantic Analysis**
   - Analyze content for semantic meaning
   - Build relationships between entries

4. **Index Building**
   - Create standard indexes (main, archives, tags)
   - Build semantic index for related content

5. **Content Processing**
   - Apply plugins to entries
   - Apply transformations (syntax highlighting, etc.)

6. **Rendering**
   - Render entries and indexes to output formats
   - Apply templates

7. **Output**
   - Write files to destination
   - Generate sitemap and other navigation aids

## Class Hierarchy

### Entry System

- **BlawdNexus::Entry** - Base class for content entries
  - **BlawdNexus::Entry::MultiMarkdown** - Markdown format entries
  - **BlawdNexus::Entry::HTML** - HTML format entries
  - **BlawdNexus::Entry::Text** - Plain text entries

### Index System

- **BlawdNexus::Index** - Base class for indexes
  - **BlawdNexus::Index::Archive** - Time-based archives
  - **BlawdNexus::Index::Tag** - Tag-based organization
  - **BlawdNexus::Index::Semantic** - Semantically related content

### Renderer System

- **BlawdNexus::Renderer** - Base class for renderers
  - **BlawdNexus::Renderer::HTML** - HTML output
  - **BlawdNexus::Renderer::RSS** - RSS feed
  - **BlawdNexus::Renderer::Atom** - Atom feed
  - **BlawdNexus::Renderer::JSON** - JSON API

### Semantic System

- **BlawdNexus::Semantic::Analyzer** - Base class for analyzers
  - **BlawdNexus::Semantic::Analyzer::TfIdf** - TF-IDF based analysis
  - **BlawdNexus::Semantic::Analyzer::Keywords** - Keyword extraction
  - **BlawdNexus::Semantic::Analyzer::BERT** - Neural network analysis
  - **BlawdNexus::Semantic::Adapter::Indexer** - Adapter for existing semantic database

### Plugin System

- **BlawdNexus::Plugin** - Base class for plugins
  - **BlawdNexus::Plugin::Syntax** - Syntax highlighting
  - **BlawdNexus::Plugin::TOC** - Table of contents generation
  - **BlawdNexus::Plugin::RelatedContent** - Insert related content links

### Command System

- **BlawdNexus::Command** - Base class for commands
  - **BlawdNexus::Command::Build** - Build the site
  - **BlawdNexus::Command::Serve** - Run a local server
  - **BlawdNexus::Command::New** - Create new content
  - **BlawdNexus::Command::IndexEntries** - Update semantic database

## Configuration System

BlawdNexus uses a YAML-based configuration system with sensible defaults:

```yaml
# bn.yml - Main configuration file

# Site-wide settings
site:
  title: "My BlawdNexus Site"
  description: "A semantic knowledge base"
  base_url: "https://example.com"
  language: "en"
  
# Content sources
content:
  sources:
    - type: directory
      path: "./content"
      pattern: "*.md"
    
# Output settings  
output:
  path: "./public"
  clean: true
  
# Semantic analysis settings
semantic:
  adapter: "Indexer"  # Use your existing semantic database
  db_path: "/Users/perigrin/dev/commonplacebook/.index.db"
  indexer_path: "/Users/perigrin/dev/commonplacebook/bin/indexer.pl"
  min_similarity: 0.3
  max_related: 5
  
# Indexes, renderers, plugins, etc.
```

## Implementation Highlights

### Modern Perl Class Syntax

BlawdNexus leverages Perl 5.40's `feature class` syntax, which provides significant advantages over the Moose-based approach in Blawd:

```perl
# Blawd (Moose-based)
package Blawd::Entry;
use Blawd::OO;
has title => (isa => 'Str', is => 'ro', required => 1);
has content => (isa => 'Str', is => 'ro', required => 1);
__PACKAGE__->meta->make_immutable;
1;

# BlawdNexus (feature class syntax)
package BlawdNexus::Entry;
use v5.40;
use feature 'class';
class BlawdNexus::Entry {
    field $title :param;
    field $content :param;
    method title { return $title }
    method content { return $content }
}
```

Benefits include:
- Cleaner, more readable syntax
- Better performance (no metaclass overhead)
- Built-in language feature rather than a dependency
- Private vs. public clear distinction

### TF-IDF Semantic Analysis

The initial semantic analysis uses TF-IDF (Term Frequency-Inverse Document Frequency) to identify content relationships:

1. Extract terms from all documents
2. Calculate term frequency in each document
3. Calculate inverse document frequency across the corpus
4. Create term vectors for each document
5. Calculate cosine similarity between document vectors
6. Identify most similar documents for each entry

This approach provides a good balance of efficiency and effectiveness, while leaving room for more sophisticated algorithms in the future.

### Pluggable Architecture

BlawdNexus uses a plugin system to extend functionality without modifying core code:

```perl
class BlawdNexus::Plugin::RelatedContent :isa(BlawdNexus::Plugin) {
    field $analyzer :param;
    
    method process($content, $context) {
        my $entry = $context->{entry};
        my $related = $analyzer->find_related($entry);
        
        # Generate HTML for related content
        my $html = "<div class='related-content'>\n";
        $html .= "<h3>Related Content</h3>\n";
        $html .= "<ul>\n";
        # ... generate links ...
        $html .= "</ul>\n</div>\n";
        
        return $content . $html;
    }
}
```

## Implementation Plan

### Phase 1: Core Infrastructure
- Project structure and organization
- Basic Entry, Index, and Renderer classes
- Configuration system

### Phase 2: Basic Site Generation
- Content parsing and processing
- Standard index generation (main, archives, tags)
- HTML, RSS, and Atom rendering
- Command-line interface

### Phase 3: Semantic Capabilities
- TF-IDF analyzer implementation
- Semantic index creation
- Related content generation
- Plugin system

### Phase 4: Advanced Features
- Additional renderers and analyzers
- Import tools for other systems
- Web editing interface
- Incremental building

## Blawd vs. BlawdNexus Comparison

| Feature | Blawd | BlawdNexus |
|---------|-------|------------|
| **Object System** | Moose | Perl 5.40 class feature |
| **Content Relationships** | Tags only | Semantic analysis |
| **Configuration** | Git-like | YAML-based |
| **Rendering** | Limited templates | Full templating system |
| **Extensibility** | Limited | Plugin architecture |
| **Performance** | Moderate | Improved (no metaclass overhead) |
| **Related Content** | None | Advanced semantic linking |
| **Incremental Building** | No | Yes (Phase 4) |
| **Live Preview** | Basic | Advanced with auto-rebuild |
| **Command-line Tool** | `blawd` | `bn` |
| **Semantic Integration** | None | Integration with existing semantic database |

## Conclusion

BlawdNexus represents a significant evolution from Blawd, embracing modern Perl features while extending functionality with semantic content analysis. By focusing on content relationships and using a clean, efficient implementation, BlawdNexus provides a powerful platform for knowledge management and content publishing that aligns with Zettlekasten principles. The integration with your existing semantic database ensures consistency between your Commonplace Book and the generated site.