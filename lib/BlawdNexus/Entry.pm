package BlawdNexus::Entry;
use v5.40;
use experimental 'class';
use experimental 'try';
use Path::Tiny;
use Time::Piece;
use BlawdNexus::Util qw(parse_date parse_tags);

class BlawdNexus::Entry {
    field $title :param :reader = '';
    field $content :param :reader;
    field $author :param :reader = '';
    field $date :param :reader = scalar Time::Piece->localtime;
    field $filename :param :reader;
    field $tags :param :reader = [];
    field $metadata :param :reader = {};

    # Lazy fields with builders
    field $body;

    # Setter methods
    method set_title($value) { $title = $value }
    method set_author($value) { $author = $value }
    method set_tags($value) { $tags = $value }

    ADJUST {
        # Parse date value, defaulting to current time if undefined
        $date = parse_date($date);

        # Ensure tags is an array
        $tags = parse_tags($tags);
    }

    # Setter methods
    method set_date($value) { $date = parse_date($value) }
    method set_metadata($value) { $metadata = $value }

    # Custom accessor methods
    method filename_base {
        my $basename = path($filename)->basename;
        $basename =~ s/\.\w+$//; # Remove file extension
        return $basename;
    }

    method body {
        return $body if defined $body;
        $body = $self->_build_body;
        return $body;
    }

    method _build_body {
        # Default implementation just returns content
        # Subclasses can override to extract body from content
        return $content;
    }

    method has_tag($tag) {
        return grep { $_ eq $tag } @$tags;
    }

    method render($renderer) {
        return $renderer->render_entry($self);
    }

    method render_fragment($renderer) {
        return $renderer->render_entry_fragment($self);
    }

    method as_hash {
        return {
            title => $title,
            author => $author,
            date => $date ? $self->_format_iso8601($date) : undef,
            filename => $filename,
            tags => $tags,
            body => $self->body,
            metadata => $metadata,
        };
    }

    # Helper method to format a Time::Piece object in ISO8601 format
    method _format_iso8601($tp) {
        return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
                     $tp->year, $tp->mon, $tp->mday,
                     $tp->hour, $tp->min, $tp->sec);
    }
}

1;
