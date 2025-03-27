package BlawdNexus::Command::Template;
use v5.40;
use experimental 'class';
use experimental 'try';
use BlawdNexus::Builder;
use Path::Tiny;
use Getopt::Long;
use BlawdNexus::Template;
use File::ShareDir::Tiny qw(dist_dir);

class BlawdNexus::Command::Template :isa(BlawdNexus::Command) {
    method description() {
        return "Manage templates for BlawdNexus";
    }
    
    method usage() {
        return "bn template <subcommand> [options]";
    }
    
    method details() {
        return "Subcommands:
  export  - Export templates to a directory
  
Options for export:
  --target=DIR  - Directory to export templates to (required)
  --force       - Overwrite existing files
  --include-all - Include all templates, even if not used in the current configuration";
    }
    
    method execute(@args) {
        # Get the subcommand
        my $subcommand = shift @args // '';
        
        if ($subcommand eq 'export') {
            return $self->execute_export(@args);
        }
        else {
            $self->error("Unknown subcommand: $subcommand");
            print $self->details();
            return 1;
        }
    }
    
    method execute_export(@args) {
        # Parse export-specific options
        my %opts;
        GetOptions(
            \%opts,
            'target=s',
            'force|f',
            'include-all',
        );
        
        # Verify required options
        unless ($opts{target}) {
            $self->error("Error: target directory is required. Use --target=DIR");
            return 1;
        }
        
        # Create target directory if it doesn't exist
        my $target_dir = path($opts{target});
        unless (-d $target_dir) {
            try {
                $target_dir->mkpath;
                $self->info("Created directory: $target_dir");
            }
            catch ($error) {
                $self->error("Failed to create directory $target_dir: $error");
                return 1;
            }
        }
        
        # Find the template directory
        my $template_dir = $self->find_template_directory();
        unless ($template_dir) {
            $self->error("Failed to locate template directory");
            return 1;
        }
        
        $self->info("Exporting templates from: $template_dir");
        $self->info("Exporting templates to: $target_dir");
        
        # Find template files
        my @template_files = $self->find_template_files($template_dir);
        
        if (!@template_files) {
            $self->warn("No template files found in $template_dir");
            return 1;
        }
        
        # Export the templates
        my $success_count = 0;
        my $error_count = 0;
        
        foreach my $file (@template_files) {
            my $rel_path = $file->relative($template_dir);
            my $target_path = $target_dir->child($rel_path);
            
            # Check if target file exists and handle force option
            if (-e $target_path && !$opts{force}) {
                $self->warn("Skipping $rel_path (already exists, use --force to overwrite)");
                next;
            }
            
            # Create parent directories if needed
            $target_path->parent->mkpath unless -d $target_path->parent;
            
            # Copy the file
            try {
                $file->copy($target_path);
                $self->verbose_log("Exported: $rel_path");
                $success_count++;
            }
            catch ($error) {
                $self->error("Failed to export $rel_path: $error");
                $error_count++;
            }
        }
        
        # Show summary
        $self->success("Exported $success_count template files to $target_dir");
        if ($error_count) {
            $self->warn("Failed to export $error_count files");
        }
        
        return $error_count ? 1 : 0;
    }
    
    method find_template_directory() {
        # Load builder to get configuration
        my $builder = BlawdNexus::Builder->new(
            config_file => $self->config_file,
        );
        
        # Try to use the configured template directory
        try {
            return $builder->get_template_dir();
        }
        catch ($error) {
            $self->warn("Failed to get template directory from configuration: $error");
        }
        
        # If that fails, check common locations
        my @locations = (
            './templates',           # Local templates
            './share/templates',     # Development templates
        );
        
        # Try shared templates directory from File::ShareDir
        try {
            my $sharedir = dist_dir('BlawdNexus');
            # In the installed version, templates are in the templates/ subdirectory
            push @locations, path($sharedir, 'templates');
            # If templates aren't in a subdirectory, use the sharedir itself
            push @locations, $sharedir;
        }
        catch ($error) {
            $self->verbose_log("Shared directory not found: $error");
        }
        
        # Try each location
        foreach my $location (@locations) {
            if (-d $location) {
                $self->verbose_log("Found template directory at: $location");
                return $location;
            }
        }
        
        # If all else fails, use the default template directory
        $self->warn("No template directory found, using default: ./templates");
        return './templates';
    }
    
    method find_template_files($template_dir) {
        my @files;
        
        # Only process .tmpl files for now
        my $iter = path($template_dir)->iterator({
            recurse => 1,
            follow_symlinks => 1,
        });
        
        while (my $file = $iter->()) {
            next if $file->is_dir;
            next unless $file =~ /\.tmpl$/;
            push @files, $file;
        }
        
        return @files;
    }
}

1;