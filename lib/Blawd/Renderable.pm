package Blawd::Renderable;
use Moose::Role;
use namespace::autoclean;

has renderer => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has _renderer_instance => (
    is         => 'ro',
    does       => 'Blawd::Renderer::API',
    lazy_build => 1,
);

sub _build__renderer_instance {
    my ($self) = @_;
    Class::MOP::load_class( $self->renderer );
    $self->renderer->new();
}

sub render             { $_[0]->_renderer_instance->render(@_) }
sub render_as_fragment { $_[0]->_renderer_instance->render_as_fragment(@_) }

1;
__END__
