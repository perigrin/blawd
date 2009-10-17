package Blawd::Renderable;
use 5.10.0;
use Moose::Role;
use MooseX::Types::Path::Class qw(File);
use namespace::autoclean;

has renderer => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_renderer { 'Blawd::Renderer::Simple' }

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

sub render_to_file {
    my ( $self, $name ) = @_;
    $name //= $self->filename;
    to_file($name)->openw->print( $self->render );
}

1;
__END__
