package Blawd::Renderer::RSS;
use Blawd::OO;
use XML::RSS;
with qw(Blawd::Renderer::API);

sub is_valid_entry {
    return unless $_[1]->isa('Blawd::Index');
    return unless $_[1]->filename eq 'rss';    # XXX probably a bad idea
    return 1;
}

has rss => (
    isa        => 'XML::RSS',
    is         => 'ro',
    lazy_build => 1,
);

has '+extension' => ( default => '.xml' );

sub _build_rss { XML::RSS->new( version => '1.0' ) }

sub render {
    my ( $self, $index ) = @_;
    $self->rss->channel(
        title => $index->title,
        link  => $self->get_link_for($index)
    );
    while ( my $entry = $index->next ) {
        my $r = $self->get_renderer_for($entry);
        $self->rss->add_item(
            title       => $entry->title,
            link        => $self->base_uri.$entry->filename.'.html',
            description => $r->render_as_fragment($entry),
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
