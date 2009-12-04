package Blawd::Renderable;
use 5.10.0;
use Moose::Role;
use MooseX::Types::Path::Class qw(File);
use namespace::autoclean;

has base_uri => ( isa => 'Str', is => 'ro', default => '' );

has renderer => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

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

sub link { $_[0]->base_uri . $_[0]->filename . $_[0]->extension }

sub render             { $_[0]->_renderer_instance->render(@_) }
sub render_as_fragment { $_[0]->_renderer_instance->render_as_fragment(@_) }
sub render_to_file     { to_File( $_[1] )->openw->print( $_[0]->render ) }

requires '_build_renderer';
1;
__END__

=head1 NAME

Blawd::Renderable

=head1 SYNOPSIS

use Blawd::Renderable;

=head1 DESCRIPTION

The Blawd::Renderable class implements ...

=head1 METHODS

=head2 _build__renderer_instance ()

=head2 link ()

Generate a link to the given Index or Entry.

=head2 render ()

Render the given Index or Entry into a full HTML document using the C<renderer>.

=head2 render_as_fragment ()

Render the given Index or Entry into an HTML fragment using the C<renderer>.

=head2 render_to_file (Str $file)

Render the given Index or Entry into a full HTML document using the
C<renderer>. Store that document in C<$file>.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
