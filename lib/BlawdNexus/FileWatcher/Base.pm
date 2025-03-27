package BlawdNexus::FileWatcher::Base;
use v5.40;
use experimental 'class';
use Path::Tiny;
use List::Util qw(any);
use Time::HiRes qw(time);
use experimental 'try';

class BlawdNexus::FileWatcher {
    field $directories :param;     # Directories to watch (array ref)
    field $filter :param = undef;  # Optional regex to filter files
    field $include_subdirs :param = 1;  # Watch subdirectories by default
    field $follow_symlinks :param = 0;  # Don't follow symlinks by default
    field $sleep_interval :param = 2;   # Seconds to sleep between checks (for polling)
    field $exclude_dirs :param = [];    # Directories to exclude (array ref)
    field $last_check_time = 0;         # Timestamp of last check
    
    # Accessor for sleep_interval
    method sleep_interval { return $sleep_interval }
    
    # Constructor validation
    ADJUST {
        die "Must provide an arrayref of directories to watch"
            unless ref $directories eq 'ARRAY';
            
        # Convert all directories to absolute paths
        for my $i (0..$#$directories) {
            $directories->[$i] = path($directories->[$i])->absolute->stringify;
            die "Directory does not exist: $directories->[$i]"
                unless -d $directories->[$i];
        }
        
        # Convert exclude_dirs to absolute paths too
        for my $i (0..$#$exclude_dirs) {
            $exclude_dirs->[$i] = path($exclude_dirs->[$i])->absolute->stringify;
        }
    }
    
    # Factory method - returns the best implementation for the current platform
    method new_best_implementation(%params) {
        # Try to load platform-specific implementations first
        if ($^O eq 'linux' && eval { require BlawdNexus::FileWatcher::Inotify; 1 }) {
            return BlawdNexus::FileWatcher::Inotify->new(%params);
        }
        elsif ($^O eq 'darwin' && eval { require BlawdNexus::FileWatcher::FSEvents; 1 }) {
            return BlawdNexus::FileWatcher::FSEvents->new(%params);
        }
        elsif ($^O eq 'MSWin32' && eval { require BlawdNexus::FileWatcher::WinChangeNotify; 1 }) {
            return BlawdNexus::FileWatcher::WinChangeNotify->new(%params);
        }
        
        # Fall back to polling implementation
        require BlawdNexus::FileWatcher::Polling;
        return BlawdNexus::FileWatcher::Polling->new(%params);
    }
    
    # Abstract methods - must be implemented by subclasses
    method wait_for_changes($timeout = undef) {
        die "Abstract method 'wait_for_changes' must be implemented by a subclass";
    }
    
    method next_change() {
        die "Abstract method 'next_change' must be implemented by a subclass";
    }
    
    method changes() {
        die "Abstract method 'changes' must be implemented by a subclass";
    }
    
    # Utility methods
    method parse_event_type($code) {
        my %types = (
            created  => 1,
            modified => 2,
            deleted  => 3,
        );
        
        return $types{$code} // $code;
    }
    
    method event_type_name($code) {
        my @types = (undef, 'created', 'modified', 'deleted');
        return $types[$code] // 'unknown';
    }
    
    # Check if a file/dir should be included in monitoring
    method _should_include($path) {
        my $path_str = "$path";
        
        # Skip excluded directories
        if (@$exclude_dirs) {
            for my $exclude (@$exclude_dirs) {
                return 0 if $path_str =~ /^\Q$exclude\E(?:\/|$)/;
            }
        }
        
        # Skip dot directories (like .git)
        return 0 if $path_str =~ m{/\.[^/]+(?:/|$)};
        
        # Apply filter if one is specified
        if (defined $filter) {
            return 0 if -d $path;  # Always include directories
            return 0 unless $path_str =~ $filter;
        }
        
        return 1;
    }
    
    # List all relevant files in watched directories
    method _all_files() {
        my @files;
        
        for my $dir (@$directories) {
            push @files, $self->_scan_directory($dir);
        }
        
        return @files;
    }
    
    # Recursively scan a directory
    method _scan_directory($dir) {
        my @files;
        
        try {
            my $dir_path = path($dir);
            my $iter = $dir_path->iterator({ recurse => $include_subdirs });
            
            while (my $path = $iter->()) {
                # Skip unless it matches our criteria
                next unless $self->_should_include($path);
                
                # Skip symlinks unless following them
                next if -l $path && !$follow_symlinks;
                
                # Add to our list
                push @files, $path->stringify;
            }
        }
        catch ($err) {
            warn "Error scanning directory $dir: $err";
        }
        
        return @files;
    }
    
    # Update the last check time
    method _update_last_check_time() {
        $last_check_time = time();
    }
    
    # Get the last check time
    method last_check_time() {
        return $last_check_time;
    }
}

1;
