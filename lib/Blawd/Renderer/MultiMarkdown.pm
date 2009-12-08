package Blawd::Renderer::MultiMarkdown;
use Blawd::OO;
use Text::MultiMarkdown ();

with qw(Blawd::Renderer::API);

has css => ( isa => 'Str', is => 'ro', default => 'site.css' );


has markdown_instance => (
    isa        => 'Text::MultiMarkdown',
    is         => 'ro',
    lazy_build => 1,
    handles    => [qw(markdown)],
);

sub _build_markdown_instance {
    Text::MultiMarkdown->new(
        document_format => 1,
        use_metadata    => 1,
        strip_metadata  => 1,
    );
}

has extension => ( isa => 'Str', is => 'ro', default => '.html' );

sub render {
    my ( $self, $page ) = @_;
    my $content = "Format: complete\n";
    $content .= 'css: ' . $self->css . "\n";
    $content .= 'XHTML Header:' . $page->headers . "\n";
    $content .= $page->content . "\n";
    if ( $page->does('Blawd::Entry::API') ) {
        $content .= "By: ${\$page->author} on ${\$page->date}\n\n";
        $content .= "Tags: " . join ' ',
          map { "[$_](" . $self->base_uri . $_ . $page->extension . ")" }
          @{ $page->tags };
        $content .= "\n";
    }
    return $self->markdown($content);
}

sub render_as_fragment {
    my ( $self, $page ) = @_;
    my $content = $page->content . "\n";
    if ( $page->does('Blawd::Entry::API') ) {
        $content .= "By: ${\$page->author} on ${\$page->date}\n\n";
        $content .= "Tags: " . join ' ',
          map { "[$_](" . $self->base_uri . $_ . $page->extension . ")" }
          @{ $page->tags };
        $content .= "\n";
    }
    return $self->markdown($content);
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
