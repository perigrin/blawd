package Blawd::Renderer::HTML;
use Blawd::OO;

with qw(Blawd::Renderer::API);

sub extension { '.html' }

has css => ( isa => 'Str', is => 'ro', default => 'site.css' );

has headers     => ( isa => 'Str', is => 'ro', default => '' );
has body_header => ( isa => 'Str', is => 'ro', default => '' );
has body_footer => ( isa => 'Str', is => 'ro', default => '' );

sub render_page {
    my ( $self, $renderable ) = @_;
    my $css = $self->css;
    my $headers     = $self->headers     // '';
    my $body_header = $self->body_header // '';
    my $body_footer = $self->body_footer // '';

    # XXX: need to figure out how to separate the rss/atom stuff out from here
    # this is a pretty big hack
    my $filename_base = $renderable->filename_base;
    if ($renderable->isa('Blawd::Index')) {
        $headers .= <<HEADERS;
                <link rel="alternate" type="application/rss+xml" title="RSS" href="${filename_base}.rss" />
                <link rel="alternate" type="application/atom+xml" title="Atom" href="${filename_base}.atom" />
HEADERS
    }

    my $content = <<PAGE_HEADER;
<!DOCTYPE html>
    <html lang="en">
	<head>
            <meta charset="utf-8" />
	    <link type="text/css" rel="stylesheet" href="$css" />
            $headers
	</head>
       <body>
       $body_header
PAGE_HEADER

    if ( $renderable->can('render_page_HTML') ) {
        $content .= $renderable->render_page_HTML($self);
    }
    else {
        $content .= $renderable->render_page($self);
    }

    $content .= <<PAGE_FOOTER;
<footer>
$body_footer
</footer>
</body>
</html>
PAGE_FOOTER

    return $content;
}

sub render_fragment {
    my ( $self, $renderable ) = @_;
    if ( $renderable->can('render_fragment_HTML') ) {
        return $renderable->render_fragment_HTML($self);
    }
    else {
        return $renderable->render_fragment($self);
    }
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Blawd::Renderer::MultiMarkdown

=head1 SYNOPSIS

use Blawd::Renderer::MultiMarkdown;

=head1 DESCRIPTION

The Blawd::Renderer::MultiMarkdown class implements conversions from
MultiMarkdown to HTML for Blawd entries.

=head1 METHODS

=head2 render (Blawd::Entry::MultiMarkdown $entry)

Render C<$entry> to a full HTML page.

=head2 render_as_fragment (Blawd::Entry::MultiMarkdown $entry)

Render C<$entry> to an HTML fragment.

=head1 PRIVATE METHODS

=head2 _build_markdown_instance

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
