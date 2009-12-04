package Blawd::Renderer::MultiMarkdown;
use Moose;
use 5.10.0;
use namespace::autoclean;
use Text::MultiMarkdown ();

with qw(Blawd::Renderer::API);

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
    my ( $self, $entry ) = @_;
    my $content = "Format: complete\n";
    $content .= 'css: ' . $self->css . "\n";
    $content .= 'XHTML Header:' . $entry->headers . "\n";
    $content .= $entry->content . "\n";
    $content .= "By: ${\$entry->author} on ${\$entry->date}\n\n";
    $content .= "Tags: " . join ' ', map {
        "[$_](" . $entry->base_uri . $_ . $entry->extension . ")"
    } @{ $entry->tags };
    $content .= "\n";
    return $self->markdown($content);
}

sub render_as_fragment {
    my ( $self, $entry ) = @_;
    my $content = $entry->content;
    $content .= "By: ${\$entry->author} on ${\$entry->date}\n\n";
    $content .= "Tags: " . join ' ', map {
        "[$_](" . $entry->base_uri . $_ . $entry->extension . ")"
    } @{ $entry->tags };
    $content .= "\n";
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
