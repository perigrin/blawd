package Blawd::Renderable;
use Blawd::OO::Role;

has title => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has filename => ( isa => 'Str', is => 'ro', required => 1, );
has filename_base => ( isa => 'Str', is => 'ro', lazy_build => 1, );
sub _build_filename_base {
    my $self = shift;
    my $filename = $self->filename;
    $filename =~ s/\.\w+?$//;
    return $filename;
}
has extension => ( isa => 'Str', is => 'ro', lazy_build => 1, );
sub _build_extension {
    my $self = shift;
    my $filename = $self->filename;
    $filename =~ /\.(\w+?)$/;
    return $1;
}

has headers => ( isa => 'Str', is => 'ro', lazy_build => 1 );
sub _build_headers { '' }

has body_header => ( isa => 'Str', is => 'ro', lazy_build => 1 );
sub _build_body_header { '' }

has body_footer => ( isa => 'Str', is => 'ro', lazy_build => 1 );
sub _build_body_footer { '' }

requires qw(_build_title render_page_default render_fragment_default);

sub render_page {
    my $self = shift;
    my ($renderer) = @_;
    confess "no renderer" unless defined $renderer;
    (my $renderer_type = blessed($renderer)) =~ s/.*:://;
    my $method = "render_page_$renderer_type";
    if ($self->can($method)) {
        return $self->$method($renderer);
    }
    return $self->render_page_default;
}

sub render_fragment {
    my $self = shift;
    my ($renderer) = @_;
    confess "no renderer" unless defined $renderer;
    (my $renderer_type = blessed($renderer)) =~ s/.*:://;
    my $method = "render_fragment_$renderer_type";
    if ($self->can($method)) {
        return $self->$method($renderer);
    }
    return $self->render_fragment_default;
}

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
