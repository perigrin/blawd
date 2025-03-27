package BlawdNexus::Builder;
use v5.40;
use experimental 'class';
use experimental 'try';
use YAML::XS qw(LoadFile);
use Path::Tiny;
use Time::Piece;
use Time::Local;
use Module::Load;
use File::ShareDir::Tiny qw(dist_dir);
use BlawdNexus::Util qw(glob_to_regex match_pattern);

class BlawdNexus::Builder {
    field $config_file :param = './bn.yml';
    field $config;
    field $storage;
    field @entries;
    field @indexes;
    field @renderers;
    field @analyzers;
    field @plugins;
    field $verbose :param = 0;

    ADJUST {
        $self->load_config();
    }

    method load_config {
        if ( -f $config_file ) {
            $config = LoadFile($config_file);
        }
        else {
            die "Configuration file not found: $config_file";
        }
    }

    method get_template_dir {
        # First check if templates directory is explicitly configured
        if ($config->{templates} && $config->{templates}{directory}) {
            my $dir = $config->{templates}{directory};
            $self->_log("Using configured template directory: $dir");
            return $dir;
        }
        
        # Next, check if a local templates directory exists
        my $local_templates = './templates';
        if (-d $local_templates) {
            $self->_log("Using local template directory: $local_templates");
            return $local_templates;
        }
        
        # Check for a local share/templates directory (during development)
        my $share_templates = './share/templates';
        if (-d $share_templates) {
            $self->_log("Using development share/templates directory: $share_templates");
            return $share_templates;
        }
        
        # Finally, fall back to shared templates directory from File::ShareDir
        my $sharedir;
        try {
            $sharedir = dist_dir('BlawdNexus');
            # In the installed version, templates are in the templates/ subdirectory
            my $templates_dir = path($sharedir, 'templates');
            if (-d $templates_dir) {
                $self->_log("Using installed shared template directory: $templates_dir");
                return $templates_dir;
            }
            
            # If templates aren't in a subdirectory, use the sharedir itself
            $self->_log("Using installed shared directory: $sharedir");
            return $sharedir;
        } 
        catch ($error) {
            # If we can't find the sharedir (e.g., during development), use a relative path
            $self->_log("Shared directory not found, falling back to default templates");
            return $local_templates;
        }
    }

    method discover_entries {
        my @entries;

        # Process each configured content source
        for my $source ( @{ $config->{content}{sources} } ) {
            if ( $source->{type} eq 'directory' ) {
                $self->_log(
                    "Discovering entries from directory: $source->{path}");
                push @entries, $self->discover_entries_from_directory($source);
            }
            elsif ( $source->{type} eq 'git' ) {
                $self->_log(
"Discovering entries from git repository: $source->{repository}"
                );
                push @entries, $self->discover_entries_from_git($source);
            }

            # Additional source types could be added here
        }

        # Sort entries by date (newest first)
        @entries = sort { $b->date <=> $a->date } @entries;

        return @entries;
    }

    method discover_entries_from_directory($source) {
        my $dir     = path( $source->{path} );
        my $pattern = $source->{pattern} // '*.md';
        my @entries;

        # Convert glob pattern to regex if it has wildcards
        my $regex_pattern;
        if ($pattern =~ /[\*\?\[\]]/) {
            $regex_pattern = glob_to_regex($pattern);
        }

        # Find all matching files
        $self->_log("Scanning directory: $dir");
        my $iter = $dir->iterator( { recurse => 1 } );
        while ( my $file = $iter->() ) {
            next if $file->is_dir;

            # Match the file against the pattern
            my $basename = $file->basename;
            if (defined $regex_pattern) {
                next unless $basename =~ $regex_pattern;
            } else {
                next unless lc($basename) eq lc($pattern);
            }

            $self->_log("Found file: $file");

            # Read the file content
            my $content = $file->slurp_utf8;

            # Determine entry type based on file extension
            my $entry_class = 'BlawdNexus::Entry::Text';    # Default
            if ( $file =~ /\.(md|mdwn|markdown)$/i ) {
                $entry_class = 'BlawdNexus::Entry::MultiMarkdown';
            }
            elsif ( $file =~ /\.(html|htm)$/i ) {
                $entry_class = 'BlawdNexus::Entry::HTML';
            }

            # Load the appropriate class
            load $entry_class;

            # Create the entry
            my $rel_path = $file->relative($dir);
            my $entry    = $entry_class->new(
                content  => $content,
                filename => "$rel_path",
                author => $config->{site}{author} // 'Unknown',    # Default
            );

            push @entries, $entry;
        }

        return @entries;
    }

    method discover_entries_from_git($source) {

        # This would use Git::Repository or similar to pull content
        # For now, warn and return an empty list
        warn "Git repositories not yet supported";
        return ();
    }

    method build_indexes {
        my @entries = $self->discover_entries();
        my @indexes;

        # Create indexes based on configuration
        for my $index_config ( @{ $config->{indexes} } ) {
            my $index_class = 'BlawdNexus::Index';

            if ( $index_config->{type} eq 'archive' ) {
                $index_class = 'BlawdNexus::Index::Archive';
            }
            elsif ( $index_config->{type} eq 'tag' ) {
                $index_class = 'BlawdNexus::Index::Tag';
            }
            elsif ( $index_config->{type} eq 'semantic' ) {
                $index_class = 'BlawdNexus::Index::Semantic';
            }

            # Load the appropriate class
            load $index_class;

            # Get entries for this index (apply filter if configured)
            my @index_entries = @entries;
            if ( my $limit = $index_config->{entries_per_page} ) {
                @index_entries = @index_entries[ 0 .. ( $limit - 1 ) ]
                  if @index_entries > $limit;
            }

            $self->_log(
"Creating index: $index_config->{name} (type: $index_config->{type})"
            );

            # Create index with appropriate parameters
            my %args = (
                title    => $index_config->{title} // $config->{site}{title},
                filename => $index_config->{name},
                entries  => \@index_entries,
                config   => $index_config,
            );

            # Add special parameters for specific index types
            if ( $index_config->{type} eq 'archive' ) {
                $args{grouping} = $index_config->{grouping} // 'monthly';
            }
            elsif ( $index_config->{type} eq 'semantic' ) {

                # Need an analyzer for semantic indexes
                my $analyzer_type = $config->{semantic}{adapter} // 'tfidf';
                my $analyzer_class;

                if ( $analyzer_type eq 'Indexer' ) {
                    $analyzer_class = "BlawdNexus::Semantic::Adapter::Indexer";
                }
                else {
                    $analyzer_class = "BlawdNexus::Semantic::Analyzer::"
                      . ucfirst($analyzer_type);
                }

                load $analyzer_class;

                my %analyzer_args = ( entries => \@entries, );

                # Add specific adapter parameters
                if ( $analyzer_type eq 'Indexer' ) {
                    $analyzer_args{db_path} = $config->{semantic}{db_path};
                    $analyzer_args{min_similarity} =
                      $config->{semantic}{min_similarity} // 0.3;
                    $analyzer_args{max_related} =
                      $config->{semantic}{max_related} // 5;
                }

                $args{analyzer} = $analyzer_class->new(%analyzer_args);
            }

            push @indexes, $index_class->new(%args);
        }

        return @indexes;
    }

    method build_renderers {
        my @renderers;

        # Create renderers based on configuration
        for my $renderer_config ( @{ $config->{renderers} } ) {
            my $renderer_class =
              "BlawdNexus::Renderer::" . ucfirst( $renderer_config->{type} );

            # Load the renderer class
            load $renderer_class;

            $self->_log("Creating renderer: $renderer_config->{type}");

            # Create the renderer
            my $renderer = $renderer_class->new(
                extension => $renderer_config->{extension},
                base_uri  => $config->{site}{base_url} // '/',
                # Make case-insensitive comparison for HTML type and ensure template_dir is passed
                (lc($renderer_config->{type}) eq 'html')
                ? ( template_dir => $self->get_template_dir() )
                : (),
            );

            push @renderers, $renderer;
        }

        return @renderers;
    }

    method build_plugins {
        my @plugins;
        
        # Create base plugin object to discover and load plugins
        load 'BlawdNexus::Plugin';
        my $plugin_loader = BlawdNexus::Plugin->new(name => 'PluginLoader');
        
        # Skip if no plugins configured
        return @plugins unless $config->{plugins};
        
        # Get configured plugins
        my %configured_plugins;
        for my $plugin_config (@{$config->{plugins}}) {
            $configured_plugins{ucfirst($plugin_config->{name})} = $plugin_config;
        }
        
        # Discover all available plugins
        foreach my $plugin_class ($plugin_loader->plugins) {
            # Skip the base class
            next if $plugin_class eq 'BlawdNexus::Plugin';
            
            # Extract the plugin name from the class name
            my $plugin_name = (split('::', $plugin_class))[-1];
            
            # Check if this plugin is configured
            if (exists $configured_plugins{$plugin_name}) {
                my $plugin_config = $configured_plugins{$plugin_name};
                $self->_log("Creating plugin: $plugin_name");
                
                # Create the plugin
                my $plugin = $plugin_class->new(
                    name    => $plugin_name,
                    options => $plugin_config->{options} // {},
                );
                
                push @plugins, $plugin;
            }
        }
        
        return @plugins;
    }

    method build {
        $self->_log("Building site from $config_file");

        # Discover content and build components
        $self->_log("Discovering entries from content sources");
        my @entries   = $self->discover_entries();
        
        $self->_log("Building indexes");
        my @indexes   = $self->build_indexes();
        
        $self->_log("Initializing renderers");
        my @renderers = $self->build_renderers();
        
        $self->_log("Loading plugins");
        my @plugins   = $self->build_plugins();

        $self->_log( sprintf( "Discovered %d entries", scalar(@entries) ) );
        $self->_log( sprintf( "Created %d indexes",    scalar(@indexes) ) );
        $self->_log(
            sprintf( "Initialized %d renderers", scalar(@renderers) ) );
        $self->_log( sprintf( "Loaded %d plugins", scalar(@plugins) ) );

        # Create and return the BlawdNexus application
        load 'BlawdNexus::App';
        return BlawdNexus::App->new(
            title     => $config->{site}{title},
            config    => $config,
            entries   => \@entries,
            indexes   => \@indexes,
            renderers => \@renderers,
            plugins   => \@plugins,
            verbose   => $verbose,
        );
    }

    method _log($message) {
        print "$message\n" if $verbose;
    }
}

1;
