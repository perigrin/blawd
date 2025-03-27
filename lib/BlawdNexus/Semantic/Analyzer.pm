package BlawdNexus::Semantic::Analyzer;
use v5.40;
use experimental 'class';

class BlawdNexus::Semantic::Analyzer {
    field $entries :param :reader;
    field $config :param :reader = {};
    field $verbose :param :reader = 0;
    
    # Abstract methods that must be implemented by subclasses
    method analyze($entry) {
        die "Abstract method 'analyze' must be implemented by subclass";
    }
    
    method find_related($entry, $count = 5) {
        die "Abstract method 'find_related' must be implemented by subclass";
    }
    
    method build_index {
        die "Abstract method 'build_index' must be implemented by subclass";
    }
    
    # Utility method for logging
    method log($message) {
        print "[Semantic Analyzer] $message\n" if $verbose;
    }
}

1;
