package BlawdNexus::FileWatcher::Event;
use v5.40;
use experimental 'class';
use Path::Tiny;

class BlawdNexus::FileWatcher::Event {
    field $type :param;  # Type of event (created, modified, deleted)
    field $event_path :param;  # Path to the changed file
    
    method type { return $type }
    method get_path { return $event_path }
    method event_path_string { return "$event_path" }
    
    method is_directory { return -d $event_path }
    method is_file { return -f $event_path }
    
    method as_hash {
        return {
            type => $type,
            path => "$event_path",
            is_dir => $self->is_directory,
        };
    }
    
    method to_string {
        my @type_names = (undef, 'created', 'modified', 'deleted');
        my $type_name = $type_names[$type] // 'unknown';
        
        return "[$type_name] $event_path";
    }
}

1;
