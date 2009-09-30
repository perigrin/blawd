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
    );
}

sub render {
    my ( $self, $entry ) = @_;
    given ( my $e = $entry ) {
        when ( $e->can('content') ) {
            return $self->markdown( $e->content );
        }
        when ( $e->can('entries') ) {
            return join "\n", map { $_->render } $e->entries;
        }
        default { return '' };
    }

}

__PACKAGE__->meta->make_immutable;
1;
__END__
