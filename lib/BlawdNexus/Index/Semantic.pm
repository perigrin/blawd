package BlawdNexus::Index::Semantic;
use v5.40;
use experimental 'class';

class BlawdNexus::Index::Semantic :isa(BlawdNexus::Index) {
    field $analyzer :param;
    field %related_cache;  # Cache for related entries to avoid recomputation
    
    method get_related_entries($entry, $count = 5) {
        my $entry_id = $entry->filename;
        
        # Check cache first
        return $related_cache{$entry_id} if exists $related_cache{$entry_id};
        
        # Get related entries from the semantic analyzer
        my $related = $analyzer->find_related($entry, $count);
        
        # Cache the results
        $related_cache{$entry_id} = $related;
        
        return $related;
    }
    
    method clear_cache {
        %related_cache = ();
    }
    
    method render($renderer) {
        if ($renderer->can('render_semantic_index')) {
            return $renderer->render_semantic_index($self);
        }
        return $renderer->render_index($self);
    }
    
    # Add an entry to the index and update relationships
    method add_entry($entry) {
        # Add to the main entries list
        my $entries = $self->entries;
        push @$entries, $entry;
        
        # Clear the cache since relationships may have changed
        $self->clear_cache;
        
        return $self;
    }
    
    # Create a recommendation block for a specific entry
    method create_recommendations($entry, $renderer, $options = {}) {
        my $related = $self->get_related_entries($entry, $options->{count} // 5);
        
        # Skip if no related entries found
        return '' unless @$related;
        
        # Render the related content block
        return $renderer->render_related_content($entry, $related, $options);
    }
}

1;
