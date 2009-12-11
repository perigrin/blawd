package Blawd::Renderer::HTML;
use Blawd::OO;

with qw(Blawd::Renderer::API);

sub extension { '.html' }

has css => ( isa => 'Str', is => 'ro', default => 'site.css' );

sub render_page {
    my ( $self, $renderable ) = @_;
    my $css = $self->css;
    my $headers     = $renderable->headers     // '';
    my $body_header = $renderable->body_header // '';
    my $body_footer = $renderable->body_footer // '';

    my $content = <<PAGE_HEADER;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
	<head>
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
$body_footer
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
