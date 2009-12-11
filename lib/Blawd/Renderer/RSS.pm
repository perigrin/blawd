package Blawd::Renderer::RSS;
use Blawd::OO;
use XML::RSS;
with qw(Blawd::Renderer::API);

sub extension { '.rss' }

has rss => (
    isa        => 'XML::RSS',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_rss { XML::RSS->new( version => '1.0' ) }

sub render_page {
    my ( $self, $index ) = @_;

    # if we have multiple actual content renderers, how do we choose which
    # one is 'canonical', to point this link to? just hardcoding html for
    # now, but this should probably be configurable or something
    my $extension = '.html';
    $self->rss->channel(
        title => $index->title,
        link  => $self->base_uri . $index->filename_base . $extension,
    );
    for my $entry ( $index->entries ) {
        $self->rss->add_item(
            title       => $entry->title,
            link        => $self->base_uri . $entry->filename_base . $extension,
            description => $entry->render_fragment($self),
            dc          => {
                date   => $entry->date . 'Z',
                author => $entry->author,
            }
        );
    }
    return $self->rss->as_string;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Blawd::Renderer::RSS - A class to render Blawd::Indexes as RSS

=head1 SYNOPSIS

use Blawd::Renderer::RSS;

=head1 DESCRIPTION

The Blawd::Renderer::RSS class implements a renderer for RSS.

=head1 METHODS

=head2 render_as_fragment (Blawd::Index $index)

Render an Index as RSS

=head2 render (Blawd::Index $index)

Render an Index as RSS

=head1 PRIVATE METHODS

=head2 _build_rss

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
