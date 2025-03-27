package BlawdNexus::FileWatcher::Polling;
use v5.40;
use experimental 'class';
use Path::Tiny;
use Time::HiRes qw(sleep time);

# Explicitly use the base class before defining the class
use BlawdNexus::FileWatcher;

class BlawdNexus::FileWatcher::Polling :isa(BlawdNexus::FileWatcher) {
    field $last_check :param = 0;
    field $changes_cache = [];
    
    method wait_for_changes($timeout = undef) {
        my $start_time = time();
        
        while (!$timeout || (time() - $start_time) < $timeout) {
            my @current_changes = $self->changes();
            return 1 if @current_changes;
            sleep($self->sleep_interval);
        }
        
        return 0;
    }
    
    method changes() {
        my @current_files = $self->_all_files();
        my @detected_changes;
        
        for my $file (@current_files) {
            my $file_path = path($file);
            my $mtime = $file_path->stat->mtime;
            
            # Check if this is a new file
            unless (grep { $_->event_path_string eq $file } @$changes_cache) {
                push @detected_changes, BlawdNexus::FileWatcher::Event->new(
                    type => 1,  # Created
                    path => $file_path,
                );
            }
        }
        
        # Check for deleted files
        for my $cached_change (@$changes_cache) {
            my $file_path = $cached_change->event_path;
            unless (-e $file_path) {
                push @detected_changes, BlawdNexus::FileWatcher::Event->new(
                    type => 3,  # Deleted
                    path => $file_path,
                );
            }
        }
        
        # Update changes cache
        $changes_cache = \@detected_changes;
        
        return @detected_changes;
    }
    
    method next_change() {
        my @changes = $self->changes();
        return $changes[0] if @changes;
        return undef;
    }
}

1;
