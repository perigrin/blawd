package Blawd::Renderable;
use 5.10.0;
use Moose::Role;
use MooseX::Types::Path::Class qw(File);
use namespace::autoclean;

has base_uri => ( isa => 'Str', is => 'ro', default => '/' );

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
    handles    => [qw(extension)],
);

sub _build__renderer_instance {
    my ($self) = @_;
    Class::MOP::load_class( $self->renderer );
    $self->renderer->new();
}

sub link { $_->base_uri . $_[0]->filename . $_[0]->extension }

sub render             { $_[0]->_renderer_instance->render(@_) }
sub render_as_fragment { $_[0]->_renderer_instance->render_as_fragment(@_) }
sub render_to_file     { to_File( $_[1] )->openw->print( $_[0]->render ) }

1;
__END__
