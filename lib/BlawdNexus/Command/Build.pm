package BlawdNexus::Command::Build;
use v5.40;
use experimental 'class';
use BlawdNexus::Builder;

class BlawdNexus::Command::Build :isa(BlawdNexus::Command) {
    method description() {
        return "Build the static site";
    }
    
    method usage() {
        return "bn build [options]";
    }
    method execute(@args) {
        print "Building site...\n";
        
        my $builder = BlawdNexus::Builder->new(
            # Use the accessor method to get config file path
            config_file => $self->config_file,
            verbose => $self->verbose, # Pass verbose flag
        );
        
        $self->verbose_log("Loading configuration from " . $self->config_file);
        my $nexus = $builder->build();
        
        $self->verbose_log("Discovered " . scalar(@{$nexus->entries}) . " entries");
        $self->verbose_log("Created " . scalar(@{$nexus->indexes}) . " indexes");
        
        # Use the config accessor method to get output directory
        my $output_dir = $self->config->{output}{path} // './public';
        $self->verbose_log("Rendering to $output_dir");
        
        $nexus->render_all($output_dir);
        
        print "Site built successfully in $output_dir\n";
        return 0;
    }
}

1;
