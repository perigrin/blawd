package BlawdNexus::Renderer::RSS;
use v5.40;
use experimental 'class';
use XML::RSS;
use HTML::Strip;
use BlawdNexus::Util qw(format_w3cdtf);

class BlawdNexus::Renderer::RSS :isa(BlawdNexus::Renderer) {
    field $item_count :param = 20;  # Default number of items to include
    field $strip;
    
    ADJUST {
        $self->set_extension('.rss');
        $strip = HTML::Strip->new();
    }
    
    method render_entry($entry) {
        # Not typically used for individual entries
        # But could provide a single-item feed if needed
        my $rss = XML::RSS->new(version => '2.0');
        
        $rss->channel(
            title => $entry->title,
            link => $self->base_uri . $entry->filename_base . '.html',
            description => $self->_get_description($entry),
            pubDate => $self->_format_date($entry->date),
        );
        
        $self->_add_entry_to_rss($rss, $entry);
        
        return $rss->as_string;
    }
    
    method render_index($index) {
        my $rss = XML::RSS->new(version => '2.0');
        
        $rss->channel(
            title => $index->title,
            link => $self->base_uri . $index->filename_base . '.html',
            description => "RSS feed for " . $index->title,
            language => 'en',
        );
        
        # Add entries to the feed, limited by item_count
        my $count = 0;
        for my $entry (@{$index->entries}) {
            last if $count >= $item_count;
            $self->_add_entry_to_rss($rss, $entry);
            $count++;
        }
        
        return $rss->as_string;
    }
    
    method _add_entry_to_rss($rss, $entry) {
        $rss->add_item(
            title => $entry->title,
            link => $self->base_uri . $entry->filename_base . '.html',
            description => $self->_get_description($entry),
            pubDate => $self->_format_date($entry->date),
            author => $entry->author,
            guid => $self->base_uri . $entry->filename_base . '.html',
        );
    }
    
    method _get_description($entry) {
        # Get a plain text excerpt from the entry's body
        my $html = $entry->render_fragment($self);
        my $text = $strip->parse($html);
        
        # Limit to a reasonable size
        if (length($text) > 500) {
            $text = substr($text, 0, 500) . '...';
        }
        
        return $text;
    }
    
    method _format_date($date) {
        # Use RFC 822 format for RSS pubDate (e.g., "Wed, 02 Oct 2002 13:00:00 GMT")
        return $date->strftime('%a, %d %b %Y %H:%M:%S %Z');
    }
    
    # These methods are required by the base class but aren't used for RSS
    method render_entry_fragment($entry) { return ''; }
    method render_index_fragment($index) { return ''; }
}

1;
