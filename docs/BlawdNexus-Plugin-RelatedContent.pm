package BlawdNexus::Plugin::RelatedContent;
use v5.40;
use feature 'class';
use URI::Escape qw(uri_escape);

class BlawdNexus::Plugin::RelatedContent :isa(BlawdNexus::Plugin) {
    field $analyzer :param;
    field $title :param = "Related Content";
    field $count :param = 3;
    field $show_similarity :param = 1;
    field $wrapper_class :param = "related-content";
    field $min_similarity :param = 0.3;
    
    method process($content, $context) {
        my $entry = $context->{entry};
        return $content unless $entry;
        
        # Get related entries from the analyzer
        my $related = $analyzer->find_related($entry, $count);
        return $content unless $related && @$related;
        
        # Filter out entries that don't meet minimum similarity
        my @filtered_related = grep { $_->{similarity} >= $min_similarity } @$related;
        return $content unless @filtered_related;
        
        # Create the HTML for related content
        my $html = "<div class='$wrapper_class'>\n";
        $html .= "<h3>$title</h3>\n";
        $html .= "<ul>\n";
        
        # Add each related entry
        for my $item (@filtered_related) {
            my $related_entry = $item->{entry};
            my $similarity = $item->{similarity};
            my $url = uri_escape($related_entry->filename_base);
            
            $html .= "<li><a href='$url.html'>$related_entry->{title}</a>";
            
            # Show similarity if requested
            if ($show_similarity) {
                $html .= sprintf(" <span class='similarity'>%.0f%%</span>", $similarity * 100);
            }
            
            $html .= "</li>\n";
        }
        
        $html .= "</ul>\n";
        $html .= "</div>\n";
        
        # Append the related content to the entry content
        return $content . $html;
    }
}

# Extended version with semantic categories
package BlawdNexus::Plugin::SemanticRecommendations;
use v5.40;
use feature 'class';
use List::Util qw(uniq);
use URI::Escape qw(uri_escape);

class BlawdNexus::Plugin::SemanticRecommendations :isa(BlawdNexus::Plugin) {
    field $analyzer :param;
    field $title :param = "You Might Also Like";
    field $count :param = 5;
    field $show_reason :param = 1;
    field $wrapper_class :param = "semantic-recommendations";
    field $group_by_tags :param = 1;
    
    method process($content, $context) {
        my $entry = $context->{entry};
        return $content unless $entry;
        
        # Get related entries from the analyzer
        my $related = $analyzer->find_related($entry, $count * 2);  # Get more than needed for grouping
        return $content unless $related && @$related;
        
        # If grouping by tags, organize entries by shared tags
        my %grouped_entries;
        
        if ($group_by_tags) {
            # First, collect all tags from the current entry
            my $entry_tags = $entry->tags;
            
            # Group related entries by which tags they share with the main entry
            for my $item (@$related) {
                my $related_entry = $item->{entry};
                my @shared_tags = grep { $related_entry->has_tag($_) } @$entry_tags;
                
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
            $grouped_entries{"Related Content"} = $related;
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
                
                $html .= "<li><a href='$url.html'>$related_entry->{title}</a>";
                
                # Show reason for recommendation if requested
                if ($show_reason) {
                    # Get top shared terms from analyzer
                    my $terms1 = $analyzer->analyze($entry);
                    my $terms2 = $analyzer->analyze($related_entry);
                    
                    # Find shared terms
                    my @shared = grep { my $t = $_; grep { $_ eq $t } @$terms2 } @$terms1;
                    
                    if (@shared) {
                        my $shared_terms = join(", ", @shared[0..min(2, $#shared)]);
                        $html .= " <span class='reason'>[$shared_terms]</span>";
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
    
    sub min {
        my ($a, $b) = @_;
        return $a < $b ? $a : $b;
    }
}

1;