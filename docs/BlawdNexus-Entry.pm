package BlawdNexus::Entry;
use v5.40;
use feature 'class';
use DateTime;
use Path::Tiny;

class BlawdNexus::Entry {
    field $title :param = '';
    field $content :param;
    field $author :param = '';
    field $date :param;
    field $filename :param;
    field $tags :param = [];
    field $metadata :param = {};
    
    # Lazy fields with builders
    field $body;
    
    ADJUST {
        # Convert date string to DateTime object if needed
        if ($date && !ref($date)) {
            $date = DateTime->parse_datetime($date);
        }
    }
    
    # Accessor methods
    method title { return $title }
    method content { return $content }
    method author { return $author }
    method date { return $date }
    method filename { return $filename }
    method filename_base {
        my $name = $filename;
        $name =~ s/\.\w+$//;
        return $name;
    }
    method tags { return $tags }
    method metadata { return $metadata }
    
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
            date => $date ? $date->iso8601 : undef,
            filename => $filename,
            tags => $tags,
            body => $self->body,
            metadata => $metadata,
        };
    }
}

package BlawdNexus::Entry::MultiMarkdown;
use v5.40;
use feature 'class';
use Text::MultiMarkdown;

class BlawdNexus::Entry::MultiMarkdown :isa(BlawdNexus::Entry) {
    field $markdown_instance;
    
    method markdown_instance {
        return $markdown_instance //= Text::MultiMarkdown->new(
            document_format => 1,
            use_metadata    => 1,
            strip_metadata  => 1,
        );
    }
    
    method _build_body {
        my $content = $self->content;
        
        # Extract front matter if present
        if ($content =~ /^---\s*\n(.*?)\n---\s*\n(.*)/s) {
            my $front_matter = $1;
            my $body = $2;
            
            # Parse front matter (basic implementation)
            while ($front_matter =~ /^(\w+):\s*(.*)$/mg) {
                my ($key, $value) = ($1, $2);
                
                # Remove quotes if present
                $value =~ s/^"(.*)"$/$1/;
                $value =~ s/^'(.*)'$/$1/;
                
                # Update fields based on front matter
                if ($key eq 'title') {
                    $title = $value;
                }
                elsif ($key eq 'author') {
                    $author = $value;
                }
                elsif ($key eq 'date') {
                    $date = DateTime->parse_datetime($value);
                }
                elsif ($key eq 'tags') {
                    if ($value =~ /^\[(.*)\]$/) {
                        $tags = [split(/\s*,\s*/, $1)];
                    } else {
                        $tags = [split(/\s+/, $value)];
                    }
                }
                else {
                    $metadata->{$key} = $value;
                }
            }
            
            # Return only the body content
            return $body;
        }
        
        # If no front matter, just return the content
        return $content;
    }
    
    method render_html {
        return $self->markdown_instance->markdown($self->body);
    }
    
    method render_fragment($renderer) {
        if ($renderer->can('render_markdown')) {
            return $renderer->render_markdown($self);
        }
        
        # Default rendering if renderer doesn't support markdown
        return $self->render_html;
    }
    
    # Class method to check if a file is a valid MultiMarkdown file
    method is_valid_file($filename) {
        return $filename =~ /\.(md|mdwn|markdown)$/i;
    }
}

1;