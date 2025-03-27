package BlawdNexus::Plugin::RelatedContent;
use v5.40;
use experimental 'class';
use URI::Escape qw(uri_escape);

class BlawdNexus::Plugin::RelatedContent :isa(BlawdNexus::Plugin) {
    field $analyzer :param = undef;
    field $title :param = undef;
    field $count :param = undef;
    field $show_similarity :param = undef;
    field $wrapper_class :param = undef;
    field $min_similarity :param = undef;

    ADJUST {
        # Initialize defaults from options if not directly provided
        $title //= $self->get_option('title', 'Related Content');
        $count //= $self->get_option('count', 3);
        $show_similarity //= $self->get_option('show_similarity', 1);
        $wrapper_class //= $self->get_option('wrapper_class', 'related-content');
        $min_similarity //= $self->get_option('min_similarity', 0.3);
    }

    method initialize($nexus) {
        # Get the analyzer from the Nexus if not provided
        unless ($analyzer) {
            for my $a (@{$nexus->analyzers}) {
                if ($a->can('find_related')) {
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
            my $title = $related_entry->title || 'Related Entry';
            my $url = uri_escape($related_entry->filename_base);

            $html .= "<li><a href='$url.html'>$title</a>";

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

1;
