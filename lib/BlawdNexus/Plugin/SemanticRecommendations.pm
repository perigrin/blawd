package BlawdNexus::Plugin::SemanticRecommendations;
use v5.40;
use experimental 'class';
use List::Util qw(uniq min);
use URI::Escape qw(uri_escape);

class BlawdNexus::Plugin::SemanticRecommendations :isa(BlawdNexus::Plugin) {
    field $analyzer :param;
    field $title :param = undef;
    field $count :param = undef;
    field $show_reason :param = undef;
    field $wrapper_class :param = undef;
    field $group_by_tags :param = undef;
    field $min_similarity :param = undef;
    
    ADJUST {
        # Initialize defaults from options if not directly provided
        $title //= $self->get_option('title', 'You Might Also Like');
        $count //= $self->get_option('count', 5);
        $show_reason //= $self->get_option('show_reason', 1);
        $wrapper_class //= $self->get_option('wrapper_class', 'semantic-recommendations');
        $group_by_tags //= $self->get_option('group_by_tags', 1);
        $min_similarity //= $self->get_option('min_similarity', 0.3);
    }
    
    method initialize($nexus) {
        # Get the analyzer from the Nexus if not provided
        unless ($analyzer) {
            for my $a (@{$nexus->analyzers}) {
                if ($a->can('find_related') && $a->can('get_shared_terms')) {
                    $analyzer = $a;
                    last;
                }
            }
            
            unless ($analyzer) {
                $self->log("No suitable semantic analyzer found. Plugin disabled.");
                $self->disable;
                return 0;
            }
        }
        
        $self->log("Initialized with analyzer: " . ref($analyzer));
        return 1;
    }
    
    method process($content, $context) {
        # Skip processing if disabled
        return $content unless $self->enabled;
        
        my $entry = $context->{entry};
        return $content unless $entry;
        
        # Get related entries from the analyzer
        my $related = $analyzer->find_related($entry, $count * 2);  # Get more than needed for grouping
        return $content unless $related && @$related;
        
        # Filter by similarity threshold
        my @filtered_related = grep { $_->{similarity} >= $min_similarity } @$related;
        return $content unless @filtered_related;
        
        # If grouping by tags, organize entries by shared tags
        my %grouped_entries;
        
        if ($group_by_tags) {
            # First, collect all tags from the current entry
            my $entry_tags = $entry->tags;
            
            # Group related entries by which tags they share with the main entry
            for my $item (@filtered_related) {
                my $related_entry = $item->{entry};
                my @shared_tags = grep { 
                    my $tag = $_;
                    grep { $_ eq $tag } @{$related_entry->tags}
                } @$entry_tags;
                
                if (@shared_tags) {
                    # Use the first shared tag as group key
                    push @{$grouped_entries{$shared_tags[0]}}, $item;
                }
                else {
                    # No shared tags - put in "More" group
                    push @{$grouped_entries{"More"}}, $item;
                }
            }
        }
        else {
            # Just use all entries in a single group
            $grouped_entries{"Related Content"} = \@filtered_related;
        }
        
        # Create the HTML
        my $html = "<div class='$wrapper_class'>\n";
        $html .= "<h3>$title</h3>\n";
        
        # Process each group
        for my $group_name (sort keys %grouped_entries) {
            my $group_entries = $grouped_entries{$group_name};
            
            # Skip empty groups
            next unless @$group_entries;
            
            # Add a subheading if we have multiple groups
            if (keys %grouped_entries > 1) {
                $html .= "<h4>$group_name</h4>\n";
            }
            
            $html .= "<ul>\n";
            
            # Add top entries from this group (limited by count)
            my $i = 0;
            for my $item (@$group_entries) {
                last if $i >= $count;
                
                my $related_entry = $item->{entry};
                my $similarity = $item->{similarity};
                my $url = uri_escape($related_entry->filename_base);
                
                $html .= "<li><a href='$url.html'>$related_entry->title</a>";
                
                # Show similarity percentage
                $html .= sprintf(" <span class='similarity'>%.0f%%</span>", $similarity * 100);
                
                # Show reason for recommendation if requested
                if ($show_reason) {
                    # Get top shared terms from analyzer
                    my $shared_terms = $analyzer->get_shared_terms($entry, $related_entry);
                    
                    if ($shared_terms && @$shared_terms) {
                        my $term_count = min(3, scalar(@$shared_terms));
                        my $shared_term_text = join(", ", @$shared_terms[0..($term_count-1)]);
                        $html .= " <span class='reason'>[$shared_term_text]</span>";
                    }
                }
                
                $html .= "</li>\n";
                $i++;
            }
            
            $html .= "</ul>\n";
        }
        
        $html .= "</div>\n";
        
        # Append the recommendations to the entry content
        return $content . $html;
    }
}

1;
