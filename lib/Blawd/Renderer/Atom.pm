package Blawd::Renderer::Atom;
use Blawd::OO;
use XML::RSS;
with qw(Blawd::Renderer::API);

use aliased 'XML::Atom::Feed';
use aliased 'XML::Atom::Entry';

sub is_valid_entry {
    return unless $_[1]->isa('Blawd::Index');
    return unless $_[1]->filename eq 'atom';    # XXX probably a bad idea
    return 1;
}

has extension => ( isa => 'Str', is => 'ro', default => '.xml' );

has atom => (
    isa        => 'XML::Atom::Feed',
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        feed_title  => 'title',
        feed_id     => 'id',
        add_entry   => 'add_entry',
        feed_as_xml => 'as_xml',
    }
);

sub _build_atom { Feed->new( Version => 1.0 ) }

sub render {
    my ( $self, $index ) = @_;
    $self->feed_title( $index->title );
    $self->feed_id( $self->get_link_for($index) );
    while ( my $post = $index->next ) {
        my $r = $self->get_renderer_for($post);
        my $entry = Entry->new( Version => 1.0 );
        $entry->title( $post->title );
        $entry->id( $self->get_link_for($post) );
        $entry->content( $r->render_as_fragment($post) );
        $self->add_entry($entry);
    }
    return $self->feed_as_xml;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
