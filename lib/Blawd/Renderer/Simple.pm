package Blawd::Renderer::Simple;
use Moose;
use 5.10.0;
use namespace::autoclean;

with qw(Blawd::Renderer::API);

sub render_as_fragment { shift->render }

sub render {
    my ( $self, $entry ) = @_;
    given ( my $e = $entry ) {
        when ( $e->can('content') ) { return $_->content }
        when ( $e->can('entries') ) {
            return join "\n", map { $_->render } $e->entries;
        }
        default { return '' };
    }

}

__PACKAGE__->meta->make_immutable;
1;
__END__
