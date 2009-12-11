package Blawd::Renderable;
use Blawd::OO::Role;
use MooseX::Types::Path::Class qw(File);
use Moose::Util::TypeConstraints;

subtype Renderer => as Object => where { $_->does('Blawd::Renderer::API') };
coerce Renderer => from Str => via {
    Class::MOP::load_class($_);
    $_->new;
};

has renderer => (
    is         => 'ro',
    isa        => 'Renderer',
    lazy_build => 1,
    coerce     => 1,
    handles    => [qw(extension)],
);

sub link { $_[0]->filename . $_[0]->extension }

sub render { my ($self) = @_; $self->renderer->render($self) }

sub render_as_fragment {
    my ($self) = @_;
    $self->renderer->render_as_fragment($self);
}

sub render_to_file {
    my ( $self, $file ) = @_;
    $self->renderer->render_to_file( $file, $self );
}

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
