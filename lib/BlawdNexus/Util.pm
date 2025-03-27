package BlawdNexus::Util;
use v5.40;
use experimental 'class';
use experimental 'signatures';
use experimental 'try';
use Unicode::Normalize qw(NFKD);
use Time::Piece;
use Time::Local qw(timelocal_posix);
use Exporter 'import';

our @EXPORT_OK = qw(slugify format_w3cdtf glob_to_regex match_pattern parse_date parse_tags);

# Convert a string to a URL-friendly slug using Unicode normalization
# Parameters:
#   $text - the text to convert to a slug
#   %options - optional parameters:
#     max_length: maximum length of the slug (default: 100)
#     separator: character to use as separator (default: '-')
sub slugify ($text, %options) {
    # Default options
    my $max_length = $options{max_length} // 100;
    my $separator = $options{separator} // '-';

    # Early return for empty input
    return '' unless defined $text && length $text;

    # Convert to lowercase
    $text = lc($text);

    # Normalize to NFKD form - separates base characters from combining marks
    $text = NFKD($text);

    # Remove combining characters (Unicode marks)
    $text =~ s/\p{Mn}//g;

    # Replace non-alphanumeric sequences with separator
    $text =~ s/[^a-z0-9]+/$separator/g;

    # Clean up separators
    $text =~ s/$separator{2,}/$separator/g;  # Remove duplicate separators
    $text =~ s/^$separator|$separator$//g;   # Remove leading/trailing separators

    # Truncate to max_length if needed
    if ($max_length && length($text) > $max_length) {
        $text = substr($text, 0, $max_length);
        $text =~ s/$separator+$//;  # Ensure no trailing separator after truncation
    }

    return $text;
}

# W3CDTF format using Time::Piece
sub format_w3cdtf {
    my ($time_piece) = @_;

    # Ensure we have a Time::Piece object
    return undef unless defined $time_piece && ref($time_piece) eq 'Time::Piece';

    # Convert to UTC if needed
    my $utc = $time_piece->tzoffset ? $time_piece->gmtime : $time_piece;

    # Format date in W3CDTF format (e.g., "2023-01-15T12:30:45Z")
    # This follows the W3C Date and Time Format (ISO 8601)
    return $utc->strftime('%Y-%m-%dT%H:%M:%SZ');
}

# Convert a simple glob pattern to a regex
sub glob_to_regex {
    my ($pattern) = @_;

    # Return undef if no pattern
    return undef unless defined $pattern;

    # If no wildcards, escape the entire string
    return qr/^\Q$pattern\E$/i unless $pattern =~ /[*?[\]]/;

    # We need to handle * and ? as wildcards, while escaping other regex metacharacters
    my $regex = $pattern;

    # Escape regex metacharacters (but not * ? [ ])
    $regex =~ s/([.+^$|(){}\\\-])/\\$1/g;

    # Convert glob wildcards to regex wildcards
    $regex =~ s/\*/.*/g;
    $regex =~ s/\?/./g;

    # Return as case-insensitive regex with start/end anchors
    return qr/^$regex$/i;
}

# Match a filename against a pattern
sub match_pattern {
    my ($filename, $pattern) = @_;

    # Get just the basename if a path is passed
    if (ref($filename) eq 'Path::Tiny') {
        $filename = $filename->basename;
    } elsif ($filename =~ m{/}) {
        $filename = (split m{/}, $filename)[-1];
    }

    # Return true if no pattern
    return 1 unless defined $pattern && length $pattern;

    # Convert to regex and match
    my $regex = glob_to_regex($pattern);
    return $filename =~ $regex;
}

# Parse various date string formats into a Time::Piece object
# Parameters:
#   $date_str - the date string or object to parse (default: current time)
# Returns:
#   A Time::Piece object representing the parsed date
sub parse_date ($date_str //= Time::Piece->localtime) {
    # If already a Time::Piece object, just return it
    return $date_str if $date_str isa Time::Piece;

    # If it's a DateTime object, convert to Time::Piece
    if (ref($date_str) eq 'DateTime') {
        return Time::Piece->localtime($date_str->epoch);
    }

    # If undefined, return current time as Time::Piece object
    return Time::Piece->localtime unless defined $date_str;

    # Quick and direct pattern match for ISO8601 with time
    # Format: "2023-04-15T15:45-05:00"
    if (my ($year, $month, $day, $hour, $min, $sec) =
        $date_str =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?(?:[+-]\d{2}:\d{2}|Z)?$/) {

        # Default seconds to 0 if not provided
        $sec //= 0;

        # Month is 0-based in timelocal_posix and year needs to be offset from 1900
        return Time::Piece->localtime(timelocal_posix($sec, $min, $hour, $day, $month - 1, $year - 1900));
    }

    # Format: "2023-04-15" (date only)
    if (my ($year, $month, $day) = $date_str =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
        # Month is 0-based in timelocal_posix and year needs to be offset from 1900
        return Time::Piece->localtime(timelocal_posix(0, 0, 0, $day, $month - 1, $year - 1900));
    }

    # Numeric timestamp
    if ($date_str =~ /^\d+$/) {
        # Parse as Unix timestamp
        return Time::Piece->localtime($date_str);
    }

    # If all parsing attempts fail, return current time as Time::Piece object
    return Time::Piece->localtime;
}

# Parse tags from various formats into an array reference
# Parameters:
#   $tags - the tags value (string, array reference, or undefined)
# Returns:
#   An array reference of tags
sub parse_tags ($tags = undef) {
    # If undefined or empty, return empty array
    return [] unless defined $tags && (ref($tags) || length($tags) > 0);

    # If already an array reference, just return it
    return $tags if ref($tags) eq 'ARRAY';

    # Check for flow style arrays [item1, item2, item3]
    if ($tags =~ /^\s*\[(.*?)\]\s*$/) {
        my $tags_str = $1;
        $tags_str =~ s/^\s+|\s+$//g;  # Trim whitespace

        if (length($tags_str) > 0) {
            my @tag_items = split(/\s*,\s*/, $tags_str);
            # Remove quotes and filter empty strings
            @tag_items = grep { length($_) > 0 }
                       map { s/^['"]|['"]$//g; $_ } @tag_items;
            return \@tag_items;
        }
        return [];
    }

    # Handle comma-separated string
    if (length($tags) > 0) {
        my @tag_items = split(/\s*,\s*/, $tags);
        @tag_items = grep { length($_) > 0 } @tag_items; # Filter out empty strings
        return \@tag_items;
    }

    # Default to empty array
    return [];
}

1;
