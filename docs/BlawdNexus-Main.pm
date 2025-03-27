package BlawdNexus;
use v5.40;
use feature 'class';

class BlawdNexus {
    field $title :param;
    field $config :param = {};
    field $entries :param = [];
    field $indexes :param = [];
    field $renderers :param = [];
    field $analyzers :param = [];
    field $plugins :param = [];
    
    # Access methods
    method title { return $title }
    method config { return $config }
    method entries { return $entries }
    method indexes { return $indexes }
    method renderers { return $renderers }
    method analyzers { return $analyzers }
    method plugins { return $plugins }
    
    # Finders
    method get_entry($name) {
        return unless $name;
        for my $entry (@$entries) {
            return $entry if $entry->filename_base eq $name;
        }
        return undef;
    }
    
    method get_index($name) {
        return unless $name;
        for my $index (@$indexes) {
            return $index if $index->filename_base eq $name;
        }
        return undef;
    }
    
    method get_renderer($name) {
        return unless $name;
        for my $renderer (@$renderers) {
            my $class = ref($renderer);
            return $renderer if $class =~ /::${name}$/;
        }
        return undef;
    }
    
    method get_analyzer($name) {
        return unless $name;
        for my $analyzer (@$analyzers) {
            my $class = ref($analyzer);
            return $analyzer if $class =~ /::${name}$/;
        }
        return undef;
    }
    
    # Build and render
    method render_all($output_dir) {
        # Create output directory if it doesn't exist
        mkdir $output_dir unless -d $output_dir;
        
        # Create subdirectories
        for my $dir (qw(tag archive)) {
            mkdir "$output_dir/$dir" unless -d "$output_dir/$dir";
        }
        
        # Render entries
        for my $entry (@$entries) {
            for my $renderer (@$renderers) {
                my $path = "$output_dir/" . $entry->filename_base . $renderer->extension;
                $renderer->render_to_file($path, $entry);
            }
        }
        
        # Render indexes
        for my $index (@$indexes) {
            for my $renderer (@$renderers) {
                my $path = "$output_dir/" . $index->filename_base . $renderer->extension;
                $renderer->render_to_file($path, $index);
            }
        }
        
        # Copy static assets (if configured)
        if (my $assets_dir = $config->{assets_dir}) {
            if (-d $assets_dir) {
                system("cp -R $assets_dir/* $output_dir/");
            }
        }
        
        return 1;
    }
}

package BlawdNexus::Builder;
use v5.40;
use feature 'class';
use YAML::XS qw(LoadFile);
use Path::Tiny;
use DateTime;
use Module::Load;

class BlawdNexus::Builder {
    field $config_file :param = './bn.yml';
    field $config;
    field $storage;
    field @entries;
    field @indexes;
    field @renderers;
    field @analyzers;
    field @plugins;
    
    ADJUST {
        $self->load_config();
    }
    
    method load_config {
        $config = LoadFile($config_file);
    }
    
    method discover_entries {
        my @entries;
        
        # Process each configured content source
        for my $source (@{$config->{content}{sources}}) {
            if ($source->{type} eq 'directory') {
                push @entries, $self->discover_entries_from_directory($source);
            }
            elsif ($source->{type} eq 'git') {
                push @entries, $self->discover_entries_from_git($source);
            }
            # Additional source types could be added here
        }
        
        # Sort entries by date (newest first)
        @entries = sort { $b->date <=> $a->date } @entries;
        
        return @entries;
    }
    
    method discover_entries_from_directory($source) {
        my $dir = path($source->{path});
        my $pattern = $source->{pattern} // '*.*';
        my @entries;
        
        # Find all matching files
        my $iter = $dir->iterator({ recurse => 1 });
        while (my $file = $iter->()) {
            next if $file->is_dir;
            next unless $file =~ /$pattern/;
            
            # Read the file content
            my $content = $file->slurp_utf8;
            
            # Determine entry type based on file extension
            my $entry_class = 'BlawdNexus::Entry::Text';  # Default
            if ($file =~ /\.(md|mdwn|markdown)$/i) {
                $entry_class = 'BlawdNexus::Entry::MultiMarkdown';
            }
            elsif ($file =~ /\.(html|htm)$/i) {
                $entry_class = 'BlawdNexus::Entry::HTML';
            }
            
            # Load the appropriate class
            load $entry_class;
            
            # Create the entry
            my $rel_path = $file->relative($dir);
            my $entry = $entry_class->new(
                content => $content,
                filename => "$rel_path",
                date => DateTime->now,  # Default, will be overridden from content
                author => $config->{site}{author} // 'Unknown',  # Default
            );
            
            push @entries, $entry;
        }
        
        return @entries;
    }
    
    method discover_entries_from_git($source) {
        # This would use Git::Repository or similar to pull content
        # For now, just return an empty list
        return ();
    }
    
    method build_indexes {
        my @indexes;
        
        # Get all available entries
        my @entries = $self->discover_entries();
        
        # Create indexes based on configuration
        for my $index_config (@{$config->{indexes}}) {
            my $index_class = 'BlawdNexus::Index';
            
            if ($index_config->{type} eq 'archive') {
                $index_class = 'BlawdNexus::Index::Archive';
            }
            elsif ($index_config->{type} eq 'tag') {
                $index_class = 'BlawdNexus::Index::Tag';
            }
            elsif ($index_config->{type} eq 'semantic') {
                $index_class = 'BlawdNexus::Index::Semantic';
            }
            
            # Load the appropriate class
            load $index_class;
            
            # Get entries for this index (apply filter if configured)
            my @index_entries = @entries;
            if (my $limit = $index_config->{entries_per_page}) {
                @index_entries = @index_entries[0..($limit-1)] if @index_entries > $limit;
            }
            
            # Create index with appropriate parameters
            my %args = (
                title => $index_config->{title} // $config->{site}{title},
                filename => $index_config->{name},
                entries => \@index_entries,
                config => $index_config,
            );
            
            # Add special parameters for specific index types
            if ($index_config->{type} eq 'archive') {
                $args{grouping} = $index_config->{grouping} // 'monthly';
            }
            elsif ($index_config->{type} eq 'semantic') {
                # Need an analyzer for semantic indexes
                my $analyzer_type = $config->{semantic}{adapter} // 'tfidf';
                my $analyzer_class;
                
                if ($analyzer_type eq 'Indexer') {
                    $analyzer_class = "BlawdNexus::Semantic::Adapter::Indexer";
                } else {
                    $analyzer_class = "BlawdNexus::Semantic::Analyzer::" . ucfirst($analyzer_type);
                }
                
                load $analyzer_class;
                
                my %analyzer_args = (
                    entries => \@entries,
                );
                
                # Add specific adapter parameters
                if ($analyzer_type eq 'Indexer') {
                    $analyzer_args{db_path} = $config->{semantic}{db_path};
                    $analyzer_args{min_similarity} = $config->{semantic}{min_similarity} // 0.3;
                    $analyzer_args{max_related} = $config->{semantic}{max_related} // 5;
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
        for my $renderer_config (@{$config->{renderers}}) {
            my $renderer_class = "BlawdNexus::Renderer::" . ucfirst($renderer_config->{type});
            
            # Load the renderer class
            load $renderer_class;
            
            # Create the renderer
            my $renderer = $renderer_class->new(
                extension => $renderer_config->{extension},
                base_uri => $config->{site}{base_url} // '/',
                %$renderer_config,  # Pass all config options to renderer
            );
            
            push @renderers, $renderer;
        }
        
        return @renderers;
    }
    
    method build_plugins {
        my @plugins;
        
        # Create plugins based on configuration
        for my $plugin_config (@{$config->{plugins}}) {
            my $plugin_class = "BlawdNexus::Plugin::" . ucfirst($plugin_config->{name});
            
            # Load the plugin class
            load $plugin_class;
            
            # Create the plugin
            my $plugin = $plugin_class->new(
                name => $plugin_config->{name},
                options => $plugin_config->{options} // {},
            );
            
            push @plugins, $plugin;
        }
        
        return @plugins;
    }
    
    method build {
        # Discover content and build components
        my @entries = $self->discover_entries();
        my @indexes = $self->build_indexes();
        my @renderers = $self->build_renderers();
        my @plugins = $self->build_plugins();
        
        # Create and return the BlawdNexus application
        return BlawdNexus->new(
            title => $config->{site}{title},
            config => $config,
            entries => \@entries,
            indexes => \@indexes,
            renderers => \@renderers,
            plugins => \@plugins,
        );
    }
}

1;