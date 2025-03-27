package BlawdNexus::Plugin;
use v5.40;
use experimental 'class';
use experimental 'try';
use Module::Pluggable search_path => ['BlawdNexus::Plugin'], require => 0, except => 'BlawdNexus::Plugin';

class BlawdNexus::Plugin {
    field $name :param :reader;
    field $options :param :reader = {};
    field $enabled :param :reader = 1;
    
    # Basic control methods
    method enable { $enabled = 1 }
    method disable { $enabled = 0 }
    
    # Get a specific option with optional default value
    method get_option($key, $default = undef) {
        return $options->{$key} // $default;
    }
    
    # Process content - must be implemented by subclasses
    method process($content, $context) {
        # Base implementation that subclasses should call
        return $content unless $self->enabled;
        die "Abstract method 'process' must be implemented by subclass";
    }
    
    # Lifecycle hooks - can be overridden by plugins
    method initialize($nexus) {
        # Called when the plugin is first loaded
        return 1;
    }
    
    method before_build($nexus) {
        # Called before site building starts
        return 1;
    }
    
    method after_build($nexus) {
        # Called after site building is complete
        return 1;
    }
    
    method before_render($renderable, $renderer) {
        # Called before an entry or index is rendered
        return 1;
    }
    
    method after_render($renderable, $renderer, $output) {
        # Called after an entry or index is rendered
        # Can modify the output if needed
        return $output;
    }
    
    # Utility methods
    method log($message) {
        # Simple logging functionality
        print "[Plugin: $name] $message\n";
        return 1;
    }
    
    # Method to load all plugins
    method load_all_plugins($nexus) {
        my @loaded_plugins;
        
        foreach my $plugin_class ($self->plugins) {
            try {
                my $plugin = $plugin_class->new(name => $plugin_class);
                $plugin->initialize($nexus);
                push @loaded_plugins, $plugin;
            } catch ($error) {
                $self->log("Failed to load plugin $plugin_class: $error");
            }
        }
        
        return \@loaded_plugins;
    }
}

1;