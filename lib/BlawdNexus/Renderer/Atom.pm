package BlawdNexus::Renderer::Atom;
use v5.40;
use experimental 'class';
use XML::Atom::Feed;
use XML::Atom::Entry;
use HTML::Strip;
use Time::Piece;
use BlawdNexus::Util qw(format_w3cdtf);

class BlawdNexus::Renderer::Atom :isa(BlawdNexus::Renderer) {
    field $item_count :param = 20;  # Default number of items to include
    field $strip;
    
    ADJUST {
        $self->set_extension('.atom');
        $strip = HTML::Strip->new();
    }
    
    method render_entry($entry) {
        # Create a feed with a single entry
        my $feed = $self->_create_feed($entry->title, 
                                      $self->base_uri . $entry->filename_base . '.html',
                                      "Atom feed for " . $entry->title);
        
        $self->_add_entry_to_feed($feed, $entry);
        
        return $feed->as_xml;
    }
    
    method render_index($index) {
        my $feed = $self->_create_feed($index->title,
                                      $self->base_uri . $index->filename_base . '.html',
                                      "Atom feed for " . $index->title);
        
        # Add entries to the feed, limited by item_count
        my $count = 0;
        for my $entry (@{$index->entries}) {
            last if $count >= $item_count;
            $self->_add_entry_to_feed($feed, $entry);
            $count++;
        }
        
        return $feed->as_xml;
    }
    
    method _create_feed($title, $link, $description) {
        my $feed = XML::Atom::Feed->new;
        $feed->title($title);
        $feed->id($link);
        
        # Add link element
        my $feed_link = XML::Atom::Link->new;
        $feed_link->rel('self');
        $feed_link->href($link);
        $feed->add_link($feed_link);
        
        # Add updated timestamp - use current time
        $feed->updated(format_w3cdtf(gmtime()));
        
        return $feed;
    }
    
    method _add_entry_to_feed($feed, $entry) {
        my $atom_entry = XML::Atom::Entry->new;
        $atom_entry->title($entry->title);
        $atom_entry->id($self->base_uri . $entry->filename_base . '.html');
        
        # Add entry link
        my $entry_link = XML::Atom::Link->new;
        $entry_link->rel('alternate');
        $entry_link->href($self->base_uri . $entry->filename_base . '.html');
        $atom_entry->add_link($entry_link);
        
        # Set the published and updated dates
        $atom_entry->published(format_w3cdtf($entry->date));
        $atom_entry->updated(format_w3cdtf($entry->date));
        
        # Add author
        my $author = XML::Atom::Person->new;
        $author->name($entry->author);
        $atom_entry->author($author);
        
        # Add content
        $atom_entry->content($self->_get_content($entry));
        
        $feed->add_entry($atom_entry);
    }
    
    method _get_content($entry) {
        my $content = XML::Atom::Content->new;
        $content->body($entry->render_fragment($self));
        $content->type('html');
        return $content;
    }
    
    # These methods are required by the base class but aren't used for Atom
    method render_entry_fragment($entry) { return ''; }
    method render_index_fragment($index) { return ''; }
}

1;
