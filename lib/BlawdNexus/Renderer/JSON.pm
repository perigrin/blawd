package BlawdNexus::Renderer::JSON;
use v5.40;
use experimental 'class';
use experimental 'try';
use JSON::PP;
use Path::Tiny;

class BlawdNexus::Renderer::JSON :isa(BlawdNexus::Renderer) {
    field $pretty :param = 1;
    field $json_encoder;
    
    ADJUST {
        $self->set_extension('.json');
        # Initialize JSON encoder
        $json_encoder = JSON::PP->new->utf8->pretty($pretty);
    }
    
    method render_entry($entry) {
        # Convert entry to a hashref
        my $data = $entry->as_hash;
        
        # Add full rendered content if available
        if ($entry->can('render_html')) {
            $data->{content_html} = $entry->render_html();
        }
        
        # Return JSON-encoded data
        return $json_encoder->encode($data);
    }
    
    method render_entry_fragment($entry) {
        # For fragments, we don't include all the metadata
        my $data = {
            title => $entry->title,
            body => $entry->body,
        };
        
        # Add HTML content if available
        if ($entry->can('render_html')) {
            $data->{content_html} = $entry->render_html();
        }
        
        return $json_encoder->encode($data);
    }
    
    method render_index($index) {
        # Basic index metadata
        my $data = {
            title => $index->title,
            filename => $index->filename,
            entry_count => $index->size,
            entries => [],
        };
        
        # Add entry summaries
        for my $entry (@{$index->entries}) {
            push @{$data->{entries}}, {
                title => $entry->title,
                url => $self->base_uri . $entry->filename_base . $self->extension,
                date => $entry->date ? $entry->_format_iso8601($entry->date) : undef,
                author => $entry->author,
                tags => $entry->tags,
            };
        }
        
        # Handle specialized index types
        if ($index->isa('BlawdNexus::Index::Tag')) {
            my %tag_counts = $index->get_tag_counts;
            $data->{tags} = [map { { name => $_, count => $tag_counts{$_} } } $index->get_tags];
        }
        elsif ($index->isa('BlawdNexus::Index::Archive')) {
            $data->{archive_groups} = [];
            for my $group ($index->get_archive_groups) {
                push @{$data->{archive_groups}}, {
                    label => $group->{label},
                    count => $group->{count},
                    entries => [map { {
                        title => $_->title,
                        url => $self->base_uri . $_->filename_base . $self->extension,
                        date => $_->date ? $_->_format_iso8601($_->date) : undef,
                    } } @{$group->{entries}}],
                };
            }
        }
        
        # Return JSON-encoded data
        return $json_encoder->encode($data);
    }
    
    method render_index_fragment($index) {
        # For fragments, just include entry titles and URLs
        my $data = {
            title => $index->title,
            entries => [map { {
                title => $_->title,
                url => $self->base_uri . $_->filename_base . $self->extension,
            } } @{$index->entries}],
        };
        
        return $json_encoder->encode($data);
    }
    
    # For specific API endpoints
    method render_api_response($status, $data) {
        my $response = {
            status => $status,
            data => $data,
        };
        
        return $json_encoder->encode($response);
    }
}

1;