package BlawdNexus::Renderer;
use v5.40;
use feature 'class';
use Path::Tiny;

class BlawdNexus::Renderer {
    field $extension :param;
    field $base_uri :param = '/';
    field $config :param = {};
    
    method extension { return $extension }
    method base_uri { return $base_uri }
    
    # Abstract methods to be implemented by subclasses
    method render_entry($entry) {
        die "Abstract method 'render_entry' must be implemented by subclass";
    }
    
    method render_entry_fragment($entry) {
        die "Abstract method 'render_entry_fragment' must be implemented by subclass";
    }
    
    method render_index($index) {
        die "Abstract method 'render_index' must be implemented by subclass";
    }
    
    method render_index_fragment($index) {
        die "Abstract method 'render_index_fragment' must be implemented by subclass";
    }
    
    method render_to_file($path, $renderable) {
        my $content = $self->render($renderable);
        path($path)->spew_utf8($content);
        return 1;
    }
}

package BlawdNexus::Renderer::HTML;
use v5.40;
use feature 'class';
use Template;
use URI::Escape qw(uri_escape);

class BlawdNexus::Renderer::HTML :isa(BlawdNexus::Renderer) {
    field $extension :param = '.html';
    field $template_dir :param = './templates';
    field $headers :param = '';
    field $body_header :param = '';
    field $body_footer :param = '';
    field $template_engine;
    
    ADJUST {
        # Initialize Template Toolkit
        $template_engine = Template->new({
            INCLUDE_PATH => $template_dir,
            INTERPOLATE  => 1,
            POST_CHOMP   => 1,
        });
    }
    
    method render_template($template, $vars) {
        my $output = '';
        $template_engine->process($template, $vars, \$output)
            or die $template_engine->error();
        return $output;
    }
    
    method render_entry($entry) {
        # Try to use a template if available
        if (-f "$template_dir/entry.tt") {
            return $self->render_template('entry.tt', {
                entry => $entry,
                content => $self->render_entry_fragment($entry),
                base_uri => $self->base_uri,
                headers => $headers,
                body_header => $body_header,
                body_footer => $body_footer,
            });
        }
        
        # Fall back to basic HTML output
        my $html = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>${\$entry->title}</title>
    <link rel="stylesheet" href="${\$self->base_uri}site.css">
    $headers
</head>
<body>
    $body_header
    <article>
        <h1>${\$entry->title}</h1>
        ${\$self->render_entry_fragment($entry)}
        <div class="meta">
            <p>By: ${\$entry->author} on ${\$entry->date}</p>
            <p>Tags: 
HTML
        
        # Add tags with links
        $html .= join(', ', map {
            my $tag = uri_escape($_);
            qq{<a href="${\$self->base_uri}tags/$tag${\$self->extension}">$_</a>}
        } @{$entry->tags});
        
        $html .= <<"HTML";
            </p>
        </div>
    </article>
    $body_footer
</body>
</html>
HTML
        
        return $html;
    }
    
    method render_entry_fragment($entry) {
        # For markdown entries
        if ($entry->can('render_html')) {
            return $entry->render_html();
        }
        
        # For HTML entries
        if ($entry->can('body_html')) {
            return $entry->body_html();
        }
        
        # For plain text entries (escape HTML)
        my $content = $entry->body;
        $content =~ s/&/&amp;/g;
        $content =~ s/</&lt;/g;
        $content =~ s/>/&gt;/g;
        return "<pre>$content</pre>";
    }
    
    method render_index($index) {
        # Try to use a template if available
        if (-f "$template_dir/index.tt") {
            return $self->render_template('index.tt', {
                index => $index,
                content => $self->render_index_fragment($index),
                base_uri => $self->base_uri,
                headers => $headers,
                body_header => $body_header,
                body_footer => $body_footer,
            });
        }
        
        # Fall back to basic HTML output
        my $html = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>${\$index->title}</title>
    <link rel="stylesheet" href="${\$self->base_uri}site.css">
    <link rel="alternate" type="application/rss+xml" title="RSS" href="${\$index->filename_base}.rss">
    <link rel="alternate" type="application/atom+xml" title="Atom" href="${\$index->filename_base}.atom">
    $headers
</head>
<body>
    $body_header
    <h1>${\$index->title}</h1>
    ${\$self->render_index_fragment($index)}
    $body_footer
</body>
</html>
HTML
        
        return $html;
    }
    
    method render_index_fragment($index) {
        my $html = '<div class="index">';
        
        for my $entry (@{$index->entries}) {
            $html .= '<article class="entry">';
            $html .= '<h2><a href="' . $self->base_uri . $entry->filename_base . $self->extension . '">'
                   . $entry->title . '</a></h2>';
            
            # Add a summary/excerpt
            my $summary = substr($entry->body, 0, 300);
            $summary =~ s/<.*?>//g; # Remove HTML tags
            $summary .= '...' if length($entry->body) > 300;
            
            $html .= '<div class="entry-summary">' . $summary . '</div>';
            
            # Add metadata
            $html .= '<div class="meta">';
            $html .= '<span class="date">' . $entry->date->strftime('%B %d, %Y') . '</span>';
            $html .= ' by <span class="author">' . $entry->author . '</span>';
            $html .= '</div>';
            
            $html .= '</article>';
        }
        
        $html .= '</div>';
        return $html;
    }
    
    method render_archive_index($archive) {
        # Try to use a template if available
        if (-f "$template_dir/archive.tt") {
            return $self->render_template('archive.tt', {
                archive => $archive,
                groups => [$archive->get_archive_groups],
                base_uri => $self->base_uri,
                headers => $headers,
                body_header => $body_header,
                body_footer => $body_footer,
            });
        }
        
        # Fall back to basic HTML output
        my $html = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>${\$archive->title}</title>
    <link rel="stylesheet" href="${\$self->base_uri}site.css">
    $headers
</head>
<body>
    $body_header
    <h1>${\$archive->title}</h1>
    <div class="archive">
HTML
        
        for my $group ($archive->get_archive_groups) {
            $html .= '<section class="archive-group">';
            $html .= '<h2>' . $group->{label} . ' (' . $group->{count} . ')</h2>';
            $html .= '<ul>';
            
            for my $entry (@{$group->{entries}}) {
                my $url = $self->base_uri . $entry->filename_base . $self->extension;
                $html .= '<li><a href="' . $url . '">' . $entry->title . '</a>';
                $html .= ' <span class="date">(' . $entry->date->strftime('%B %d, %Y') . ')</span>';
                $html .= '</li>';
            }
            
            $html .= '</ul></section>';
        }
        
        $html .= <<"HTML";
    </div>
    $body_footer
</body>
</html>
HTML
        
        return $html;
    }
    
    method render_tag_index($tag_index) {
        # Try to use a template if available
        if (-f "$template_dir/tags.tt") {
            return $self->render_template('tags.tt', {
                index => $tag_index,
                tags => [$tag_index->get_tags],
                tag_counts => {$tag_index->get_tag_counts},
                base_uri => $self->base_uri,
                headers => $headers,
                body_header => $body_header,
                body_footer => $body_footer,
            });
        }
        
        # Fall back to basic HTML output
        my $html = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>${\$tag_index->title}</title>
    <link rel="stylesheet" href="${\$self->base_uri}site.css">
    $headers
</head>
<body>
    $body_header
    <h1>${\$tag_index->title}</h1>
    <div class="tags">
HTML
        
        my %counts = $tag_index->get_tag_counts;
        my @tags = sort { $a cmp $b } $tag_index->get_tags;
        
        for my $tag (@tags) {
            my $tag_url = uri_escape($tag);
            $html .= '<div class="tag">';
            $html .= '<a href="' . $self->base_uri . 'tag/' . $tag_url . $self->extension . '">'
                   . $tag . '</a> (' . $counts{$tag} . ')';
            $html .= '</div>';
        }
        
        $html .= <<"HTML";
    </div>
    $body_footer
</body>
</html>
HTML
        
        return $html;
    }
    
    method render_semantic_index($semantic_index) {
        # This would be better implemented with a proper template
        # For now, just return a basic index
        return $self->render_index($semantic_index);
    }
}

1;