package BlawdNexus::Index::Tag;
use v5.40;
use experimental 'class';

class BlawdNexus::Index::Tag :isa(BlawdNexus::Index) {
    field %tagged_entries;
    
    ADJUST {
        $self->build_tag_index();
    }
    
    method build_tag_index {
        for my $entry (@{$self->entries}) {
            for my $tag (@{$entry->tags}) {
                push @{$tagged_entries{$tag}}, $entry;
            }
        }
        
        # Sort entries within each tag
        for my $tag (keys %tagged_entries) {
            @{$tagged_entries{$tag}} = sort { 
                $b->date <=> $a->date 
            } @{$tagged_entries{$tag}};
        }
    }
    
    method get_tags {
        return sort keys %tagged_entries;
    }
    
    method get_entries_for_tag($tag) {
        return $tagged_entries{$tag} // [];
    }
    
    method get_tag_counts {
        my %counts;
        for my $tag (keys %tagged_entries) {
            $counts{$tag} = scalar(@{$tagged_entries{$tag}});
        }
        return %counts;
    }
    
    method render($renderer) {
        if ($renderer->can('render_tag_index')) {
            return $renderer->render_tag_index($self);
        }
        return $renderer->render_index($self);
    }
}

1;
