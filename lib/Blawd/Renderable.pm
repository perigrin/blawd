package Blawd::Renderable;
use Moose::Role;
use namespace::autoclean;

requires 'render';

has renderer => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Blawd::Renderer::Simple',
);

has _renderer_instance => (
    does       => 'Blawd::Renderer::API',
    handles    => 'Blawd::Renderer::API',
    lazy_build => 1,
);

sub _build__renderer_instance {
    my ($self) = @_;
    Class::MOP::load_class( $self->renderer );
    $self->renderer->new();
}

1;
__END__
