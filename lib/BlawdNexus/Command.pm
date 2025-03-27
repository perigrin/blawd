package BlawdNexus::Command;
use v5.40;
use experimental 'class';
use YAML::XS qw(LoadFile Dump);
use Term::ANSIColor;
use experimental 'try';

class BlawdNexus::Command {
    field $config_file :param :reader = './bn.yml';
    field $verbose :param :reader = 0;
    field $colorize :param :reader = 1;
    field $config;
    
    ADJUST {
        $self->load_config();
    }
    
    method load_config {
        try {
            $config = LoadFile($self->config_file);
        } catch ($error) {
            $self->error("Failed to load config file '" . $self->config_file . "': $error");
            exit 1;
        }
    }
    
    method config { return $config }
    
    method execute(@args) {
        die "Abstract method 'execute' must be implemented by subclass";
    }
    
    # Command metadata methods - to be overridden by subclasses
    method description() {
        return "No description available";
    }
    
    method usage() {
        my $cmd_name = lc((split('::', ref($self) || __PACKAGE__))[-1]);
        return "bn $cmd_name [options]";
    }
    
    method details() {
        return "";
    }
    
    # Logging methods with color support
    method info($message) {
        my $formatted = $self->colorize() ? colored(['green'], "INFO: ") . $message : "INFO: $message";
        print "$formatted\n";
    }
    
    method warn($message) {
        my $formatted = $self->colorize() ? colored(['yellow'], "WARNING: ") . $message : "WARNING: $message";
        print STDERR "$formatted\n";
    }
    
    method error($message) {
        my $formatted = $self->colorize() ? colored(['bold red'], "ERROR: ") . $message : "ERROR: $message";
        print STDERR "$formatted\n";
    }
    
    method verbose_log($message, $level = 1) {
        return unless $self->verbose >= $level;
        my $prefix = "VERBOSE: " . ("+" x $level) . " ";
        my $formatted = $self->colorize() ? colored(['blue'], $prefix) . $message : "$prefix$message";
        print "$formatted\n";
    }
    
    method success($message) {
        my $formatted = $self->colorize() ? colored(['bold green'], "SUCCESS: ") . $message : "SUCCESS: $message";
        print "$formatted\n";
    }
    
    method display_config {
        return unless $self->verbose >= 2;
        $self->verbose_log("Configuration:", 2);
        print Dump($self->config);
    }
    
    # Progress indicator for long-running operations
    field $progress_char = 0;
    method progress($message = '') {
        return unless -t STDOUT;  # Only if terminal
        
        my @chars = qw(| / - \\);
        $progress_char = ($progress_char + 1) % scalar(@chars);
        
        my $indicator = $self->colorize() ? colored(['cyan'], $chars[$progress_char]) : $chars[$progress_char];
        print "\r$indicator $message";
    }
    
    method end_progress {
        return unless -t STDOUT;  # Only if terminal
        print "\r" . (" " x 80) . "\r";  # Clear the line
    }
    
    # Utility to prompt for user input
    method prompt($message, $default = undef) {
        my $prompt = $message;
        $prompt .= " [$default]" if defined $default;
        $prompt .= ": ";
        
        print $prompt;
        my $answer = <STDIN>;
        chomp $answer;
        
        return $answer eq '' ? $default : $answer;
    }
    
    # Ask for confirmation
    method confirm($message, $default = 'y') {
        my $yn = $default =~ /^y/i ? '[Y/n]' : '[y/N]';
        my $prompt = "$message $yn: ";
        
        print $prompt;
        my $answer = <STDIN>;
        chomp $answer;
        
        return 1 if $answer eq '' && $default =~ /^y/i;
        return 0 if $answer eq '' && $default =~ /^n/i;
        return $answer =~ /^y/i;
    }
}

1;
