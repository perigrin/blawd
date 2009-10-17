package Blawd::Renderer::RSS;
use Moose;
use 5.10.0;
use namespace::autoclean;
use XML::RSS;

with qw(Blawd::Renderer::API);

has rss => (
    isa        => 'XML::RSS',
    is         => 'ro',
    lazy_build => 1,
);

has extension => ( isa => 'Str', is => 'ro', default => '.xml' );

sub _build_rss { XML::RSS->new( version => '1.0' ) }

sub render_as_fragment { shift->render }

sub render {
    my ( $self, $index ) = @_;
    $self->rss->channel(
        title => $index->title,
        link  => $index->link,
    );
    while ( my $entry = $index->next ) {
        $self->rss->add_item(
            title       => $entry->title,
            link        => $entry->link,
            description => $entry->render_as_fragment,
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
