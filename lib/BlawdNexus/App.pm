package BlawdNexus::App;
use v5.40;
use experimental 'class';
use Path::Tiny;

class BlawdNexus::App {
    field $title :param :reader;
    field $config :param :reader = {};
    field $entries :param :reader = [];
    field $indexes :param :reader = [];
    field $renderers :param :reader = [];
    field $analyzers :param :reader = [];
    field $plugins :param :reader = [];
    field $verbose :param :reader = 0;
    
    method _log($message) {
        print "$message\n" if $verbose;
    }
    
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
        path($output_dir)->mkpath unless -d $output_dir;
        
        # Clean output directory if configured
        if ($config->{output}{clean}) {
            $self->clean_output_dir($output_dir);
        }
        
        # Create subdirectories
        for my $dir (qw(tag archive)) {
            path("$output_dir/$dir")->mkpath unless -d "$output_dir/$dir";
        }
        
        # Apply plugins to entries if applicable
        if (@$plugins) {
            $self->_log("Applying plugins to entries");
            $self->apply_plugins();
        }
        
        # Render entries
        $self->_log("Rendering entries:");
        for my $entry (@$entries) {
            for my $renderer (@$renderers) {
                # Skip RSS/Atom renderers for individual entries
                next if $renderer->isa('BlawdNexus::Renderer::RSS') ||
                        $renderer->isa('BlawdNexus::Renderer::Atom');
                
                my $path = "$output_dir/" . $entry->filename_base . $renderer->extension;
                $self->_log(" - $path");
                $renderer->render_to_file($path, $entry);
            }
        }
        
        # Render indexes
        $self->_log("Rendering indexes:");
        for my $index (@$indexes) {
            for my $renderer (@$renderers) {
                my $path = "$output_dir/" . $index->filename_base . $renderer->extension;
                $self->_log(" - $path");
                $renderer->render_to_file($path, $index);
            }
        }
        
        # Render tag pages if we have a tag index
        for my $index (@$indexes) {
            if ($index->isa('BlawdNexus::Index::Tag')) {
                $self->_log("Rendering tag pages:");
                $self->render_tag_pages($index, $output_dir);
            }
        }
        
        # Copy static assets (if configured)
        if (my $assets_dir = $config->{assets_dir}) {
            if (-d $assets_dir) {
                $self->_log("Copying static assets from $assets_dir");
                $self->copy_static_assets($assets_dir, $output_dir);
            }
        }
        
        return 1;
    }
    
    method clean_output_dir($output_dir) {
        my $dir = path($output_dir);
        
        # Skip if directory doesn't exist
        return unless -d $dir;
        
        # Clear the directory, but don't remove the directory itself
        my $iter = $dir->iterator;
        while (my $path = $iter->()) {
            if (-d $path) {
                # Recursively remove directories
                $path->remove_tree({ safe => 0 });
            } else {
                # Remove files
                $path->remove;
            }
        }
    }
    
    method render_tag_pages($tag_index, $output_dir) {
        # Get HTML renderer (or any renderer that supports render_tag_entries)
        my $renderer;
        for my $r (@$renderers) {
            if ($r->can('render_tag_entries')) {
                $renderer = $r;
                last;
            }
        }
        return unless $renderer;
        
        # Create tag directory
        my $tag_dir = path("$output_dir/tag");
        $tag_dir->mkpath unless -d $tag_dir;
        
        # Render a page for each tag
        for my $tag ($tag_index->get_tags()) {
            my $entries = $tag_index->get_entries_for_tag($tag);
            my $tag_filename = $tag;
            $tag_filename =~ s/[^a-zA-Z0-9]/-/g;  # sanitize
            
            my $path = "$tag_dir/$tag_filename" . $renderer->extension;
            $self->_log(" - $path");
            my $content = $renderer->render_tag_entries($tag, $entries);
            
            path($path)->spew_utf8($content);
        }
    }
    
    method copy_static_assets($assets_dir, $output_dir) {
        my $src = path($assets_dir);
        my $dst = path($output_dir);
        
        # Skip if source directory doesn't exist
        return unless -d $src;
        
        # Copy all files recursively
        my $iter = $src->iterator({ recurse => 1 });
        while (my $path = $iter->()) {
            next if $path->is_dir;
            
            # Calculate relative path
            my $rel = $path->relative($src);
            my $target = $dst->child($rel);
            
            # Create parent directories if they don't exist
            $target->parent->mkpath unless -d $target->parent;
            
            # Copy the file
            $self->_log(" - $rel");
            $path->copy($target);
        }
    }
    
    method apply_plugins {
        for my $entry (@$entries) {
            for my $plugin (@$plugins) {
                # Skip plugins that don't have a process method
                next unless $plugin->can('process');
                
                # Process the entry with the plugin
                # The plugin might modify the entry's content
                # or add related content
                $plugin->process($entry, {
                    app => $self,
                    config => $config,
                });
            }
        }
    }
}

1;
