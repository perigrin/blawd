# Integrating BlawdNexus with Your Existing Semantic Database

## Overview

Instead of building a new semantic analysis system from scratch, BlawdNexus will leverage your existing semantic analyzer in `bin/indexer` and the database it generates. This approach ensures consistency between your Commonplace Book and the new site generator while avoiding duplication of effort.

## Database Integration

### Database Schema Understanding

The adapter assumes your semantic database has at least the following tables:

1. **documents** - Stores metadata about each content file
   - `id` - Document identifier
   - `path` - Path to the document file
   - `title` - Document title

2. **document_terms** - Stores term relevance for each document
   - `document_id` - Reference to documents table
   - `term` - The term/keyword
   - `weight` - TF-IDF or other relevance score

3. **similarities** - Stores relationships between documents
   - `document1_id` - First document
   - `document2_id` - Second document
   - `similarity` - Similarity score (likely cosine similarity)

If your database schema differs, the adapter will need to be adjusted to match.

## Workflow Integration

### 1. Content Indexing

When new content is created or updated, it needs to be indexed in the semantic database:

```bash
# Index all entries in the BlawdNexus content sources
bn index-entries --all

# Index only new entries
bn index-entries --new
```

The indexing command:
1. Discovers all content files from configured sources
2. For each file, calls your existing `indexer.pl` script
3. Updates the semantic database with new document vectors and similarities

### 2. Semantic Integration During Build

During the site build process:

1. The `BlawdNexus::Semantic::Adapter::Indexer` connects to your existing database
2. Maps entry filenames to document IDs in the database
3. Retrieves semantic relationships for each entry
4. Makes this data available to renderers and plugins

### 3. Related Content Display

The semantic data powers various site features:

1. **Related Content Plugin**: Displays semantically related entries
2. **Semantic Recommendations**: Groups recommendations by category
3. **Semantic Search**: Enables searching by concept rather than just keywords

## Implementation Components

### 1. Database Adapter

The `BlawdNexus::Semantic::Adapter::Indexer` class:
- Connects to your existing semantic database
- Maps entries to document IDs
- Retrieves related content
- Exposes key terms and semantic relationships

### 2. Indexing Command

The `BlawdNexus::Command::IndexEntries` command:
- Discovers content from configured sources
- Calls your existing indexer script for each file
- Updates the semantic database

### 3. Related Content Plugins

Two plugins are provided:
- `BlawdNexus::Plugin::RelatedContent`: Simple related content display
- `BlawdNexus::Plugin::SemanticRecommendations`: Advanced recommendations grouped by topic

## Configuration

```yaml
# In bn.yml
semantic:
  adapter: "Indexer"  # Use the Indexer adapter
  db_path: "/Users/perigrin/dev/commonplacebook/.index.db"
  indexer_path: "/Users/perigrin/dev/commonplacebook/bin/indexer.pl"
  min_similarity: 0.3
  max_related: 5

plugins:
  - name: "RelatedContent"
    options:
      title: "Related Content"
      count: 3
      show_similarity: true
  
  - name: "SemanticRecommendations"
    options:
      title: "You Might Also Like"
      count: 5
      group_by_tags: true
      show_reason: true
```

## Advantages of This Approach

1. **Consistency**: Ensures recommendations are consistent with your existing semantic system
2. **Efficiency**: Avoids duplicating analysis that's already been done
3. **Familiarity**: Leverages your existing `indexer.pl` script that you're already familiar with
4. **Extensibility**: Allows for future enhancements to the semantic analysis while maintaining compatibility

## Considerations

1. **Database Access**: Ensure the database is accessible from where BlawdNexus runs
2. **Performance**: For large sites, consider optimizing database queries
3. **Schema Changes**: If you modify your semantic database schema, update the adapter accordingly
4. **Content Synchronization**: Ensure content is indexed before building the site