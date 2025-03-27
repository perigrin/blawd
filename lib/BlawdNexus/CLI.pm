package BlawdNexus::CLI;
use v5.40;
use experimental 'class';
use Getopt::Long qw(:config bundling pass_through);
use Pod::Usage;
use experimental 'try';
use Term::ANSIColor;
use Module::Pluggable search_path => ['BlawdNexus::Command'], require => 0, sub_name => 'available_commands';

class BlawdNexus::CLI {
    # Get command class from command name
    method get_command_class($command_name) {
        foreach my $class ($self->available_commands) {
            my $short_name = lc((split('::', $class))[-1]);
            # Convert kebab-case to snake_case for matching
            my $cmd_name = lc($command_name);
            $cmd_name =~ s/-/_/g;
            $short_name =~ s/-/_/g;
            return $class if $short_name eq $cmd_name;
        }
        return undef;
    }
    
    # Get all available command names
    method get_command_names() {
        my @names;
        foreach my $class ($self->available_commands) {
            my $name = lc((split('::', $class))[-1]);
            # Convert snake_case to kebab-case for display
            $name =~ s/_/-/g;
            push @names, $name;
        }
        return sort @names;
    }

    # Main entry point
    method run(@args) {
        try {
            # Parse global options
            my %opts;
            Getopt::Long::GetOptions(
                \%opts,
                'help|h',
                'config|c=s',
                'verbose|v+',
                'version',
                'color!',
            );

            # Handle --version
            if ($opts{version}) {
                $self->show_version();
                return 0;
            }

            # Handle --help with no command
            if ($opts{help} && !@args) {
                $self->show_help();
                return 0;
            }

            # Require a command
            if (!@args) {
                $self->show_help("Error: No command specified");
                return 1;
            }

            # Get the command name and remove it from args
            my $command_name = shift @args;

            # Handle special case of 'help <command>'
            if ($command_name eq 'help') {
                $self->show_command_help(shift @args);
                return 0;
            }

            # See if we have a registered command
            my $command_class = $self->get_command_class($command_name);
            if (!$command_class) {
                $self->show_error("Unknown command: $command_name");
                $self->show_help();
                return 1;
            }

            # Handle --help for a specific command
            if ($opts{help}) {
                $self->show_command_help($command_name);
                return 0;
            }

            # Already have the command class from above

            # Dynamically load the command class
            try {
                eval "require $command_class";
                die $@ if $@;
            } catch ($error) {
                $self->show_error("Failed to load command class '$command_class': $error");
                return 1;
            }

            # Create the command instance
            my $cmd = $command_class->new(
                config_file => $opts{config} // './bn.yml',
                verbose => $opts{verbose} // 0,
                #                color => $opts{color} // 1,
            );

            # Execute the command
            return $cmd->execute(@args);
        } catch ($error) {
            $self->show_error("An unexpected error occurred: $error");
            return 1;
        }
    }

    # Display version information
    method show_version {
        # Get version from package variable
        my $version = $BlawdNexus::VERSION // '0.1.0';
        print "BlawdNexus v$version\n";
    }

    # Display main help
    method show_help($error = '') {
        # Show error if provided
        if ($error) {
            $self->show_error($error);
            print "\n";
        }

        # Show general usage
        print "Usage: bn [options] command [command-options]\n\n";

        # Show available commands
        print "Commands:\n";
        foreach my $cmd_name ($self->get_command_names) {
            my $cmd_class = $self->get_command_class($cmd_name);
            # Create a temporary instance to get description
            my $tmp_cmd;
            try {
                $tmp_cmd = $cmd_class->new(config_file => './bn.yml');
            } catch ($error) {
                # Fall back to class method if instance creation fails
                if ($cmd_class->can('description')) {
                    printf "  %-15s %s\n", $cmd_name, $cmd_class->description();
                    next;
                } else {
                    printf "  %-15s %s\n", $cmd_name, "No description available";
                    next;
                }
            }
            printf "  %-15s %s\n", $cmd_name, $tmp_cmd->description();
        }

        # Show global options
        print "\nGlobal Options:\n";
        print "  --help, -h       Show this help message\n";
        print "  --config, -c     Path to configuration file (default: ./bn.yml)\n";
        print "  --verbose, -v    Show verbose output (can be used multiple times)\n";
        print "  --version        Show version information\n";
        print "  --color, --no-color Enable/disable colored output\n";

        # Show additional help info
        print "\nFor help on a specific command, use: bn help <command>\n";
    }

    # Display help for a specific command
    method show_command_help($command = '') {
        # If no command specified, show general help
        if (!$command) {
            $self->show_help();
            return;
        }

        # Check if command exists
        my $command_class = $self->get_command_class($command);
        if (!$command_class) {
            $self->show_error("Unknown command: $command");
            $self->show_help();
            return;
        }

        # Try to create an instance to get the metadata
        my $cmd;
        try {
            $cmd = $command_class->new(config_file => './bn.yml');
        } catch ($error) {
            # If we can't create an instance, try class methods
            if ($command_class->can('usage') && $command_class->can('description')) {
                print $command_class->usage() . "\n\n";
                print $command_class->description() . "\n\n";
                
                if ($command_class->can('details') && $command_class->details()) {
                    print $command_class->details() . "\n\n";
                } else {
                    # Try to extract POD
                    eval "require $command_class";
                    if (!$@) {
                        pod2usage(-verbose => 2, -sections => "COMMAND/$command", -exitval => 'NOEXIT');
                    }
                }
                return;
            }
            
            # If all else fails, show the error
            $self->show_error("Could not load command class: $error");
            return;
        }
        
        # Show command metadata from the instance
        print $cmd->usage() . "\n\n";
        print $cmd->description() . "\n\n";
        
        if ($cmd->details()) {
            print $cmd->details() . "\n\n";
        } else {
            # Try to extract POD
            pod2usage(-verbose => 2, -sections => "COMMAND/$command", -exitval => 'NOEXIT');
        }
    }

    # Display an error message
    method show_error($message) {
        print STDERR colored(['bold red'], "ERROR: $message\n");
    }
}

1;
