package Blawd::Renderer::Atom;
use Blawd::OO;
use XML::RSS;
with qw(Blawd::Renderer::API);

use aliased 'XML::Atom::Feed';
use aliased 'XML::Atom::Entry';

sub extension { '.atom' }

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

sub render_page {
    my ( $self, $index ) = @_;
    # if we have multiple actual content renderers, how do we choose which
    # one is 'canonical', to point this link to? just hardcoding html for
    # now, but this should probably be configurable or something
    my $extension = '.html';
    $self->feed_title( $index->title );
    $self->feed_id( $self->base_uri . $index->filename_base . $extension );
    for  my $post ( $index->entries ) {
        my $entry = Entry->new( Version => 1.0 );
        $entry->title( $post->title );
        $entry->id( $self->base_uri . $post->filename_base . $extension );
        $entry->content( $post->render_fragment($self) );
        $self->add_entry($entry);
    }
    return $self->feed_as_xml;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
