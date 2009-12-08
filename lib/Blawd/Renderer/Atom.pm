package Blawd::Renderer::Atom;
use Blawd::OO;
use XML::RSS;
with qw(Blawd::Renderer::API);

use aliased 'XML::Atom::Feed';
use aliased 'XML::Atom::Entry';

has extension => ( isa => 'Str', is => 'ro', default => '.xml' );

has atom => (
    isa        => 'XML::ATOM',
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        feed_title  => 'title',
        feed_id     => 'id',
        add_entry   => 'add_entry',
        feed_as_xml => 'as_xml',
    }
);

sub _build_atom { Feed->new() }

alias 'render_as_fragment' => 'render';

sub render {
    my ( $self, $index ) = @_;
    $self->feed_title( $index->title );
    $self->feed_id( $index->link );
    while ( my $post = $index->next ) {
        my $entry = Entry->new();
        $entry->title( $post->title );
        $entry->id( $post->link );
        $entry->content( $post->render_as_fragment );
        $self->add_entry($entry);
    }
    return $self->feed_as_xml;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
