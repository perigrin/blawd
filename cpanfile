# Perl version requirements
requires 'perl', '5.40.0';

# Plugin Management
requires 'Module::Pluggable';     # Plugin system

# Non-core modules we depend on
requires 'Path::Tiny';           # File path manipulation
requires 'URI::Escape';          # URL encoding/decoding
requires 'YAML::XS';             # Configuration file handling
requires 'Text::Template', '>= 1.59'; # Template processing for Text::Template engine
requires 'File::ShareDir::Tiny'; # For shared templates directory

# Markdown processing
requires 'Text::MultiMarkdown';  # Content formatting

# Feed generation
requires 'XML::RSS';             # RSS feed generation
requires 'XML::Atom::Feed';      # Atom feed generation

# Database support for semantic indexing
requires 'DBI';                  # Database interface
requires 'DBD::SQLite';          # SQLite driver

# HTML processing
requires 'HTML::Strip';          # Strip HTML tags

# Console UI improvements
requires 'Term::ANSIColor';      # Colorized terminal output

# Tests only
on 'test' => sub {
    requires 'Test2::V0';        # Modern testing framework
};

# Development only
on 'develop' => sub {
    requires 'Module::Build::Tiny'; # Build system
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
};
