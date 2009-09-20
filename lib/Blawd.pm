package  Blawd;
use Moose;
use 5.10.0;
use namespace::autoclean;

our $VERSION = '0.01';

use Blawd::GitInterface;
use MooseX::Types::Path::Class qw(Dir);

has repo => (
    isa      => Dir,
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has view => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Blawd::View::Test'
);

has _git => (
    isa        => 'Blawd::GitInterface',
    accessor   => 'git',
    lazy_build => 1,
);

sub _build__git {
    my $self = shift;
    Blawd::GitInterface->new( gitdir => $self->repo );
}
has _view_instance => (
    does       => 'Blawd::View::API',
    handles    => 'Blawd::View::API',
    lazy_build => 1,
);

sub _build__view_instance {
    my ($self) = @_;
    Class::MOP::load_class( $self->view );
    $self->view->new();
}

sub run {
    my $self = shift;
    $self->render( $self->git->find_entries );
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Blawd - A Git based Blog

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

	use Blawd;
	Blawd->new(directory => '/path/to/git', output => '/path/to/htdocs' );
	
=head1 DESCRIPTION

=head1 SUBROUTINES / METHODS

=head2 run()

Generate a blog from the directory given

=head1 DEPENDENCIES

Moose, Git::PurePerl, namespace::autoclean, MooseX::Getopt

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
