package Blawd::Renderer::Simple;
use Moose;
use 5.10.0;
use namespace::autoclean;
use MooseX::Aliases;

with qw(Blawd::Renderer::API);

alias render_as_fragment => 'render';

sub render {
    my ( $self, $entry ) = @_;
    given ($entry) {
        when ( $_->can('content') ) { return $_->content }
        when ( $_->can('entries') ) {
            return join "\n", map { $_->render } $_->entries;
        }
        default { return '' };
    }

}

__PACKAGE__->meta->make_immutable;
1;
__END__
