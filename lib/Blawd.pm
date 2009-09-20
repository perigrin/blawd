package  Blawd;
use Moose;
use 5.10.0;
use namespace::autoclean;

our $VERSION = '0.01';

use Git::PurePerl;
use MooseX::Getopt;
use MooseX::Types::Path::Class qw(Dir);

has directory => (
    isa      => Dir,
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has git => (
    isa        => 'Git::PurePerl',
    is         => 'ro',
    traits     => ['NoGetopt'],
    lazy_build => 1,
);

sub _build_git {
    my $self = shift;
    Git::PurePerl->new( directory => $self->directory );
}

has view => (
    does       => 'Blawd::View::API',
    handles    => 'Blawd::View::API',
    lazy_build => 1,
);

sub _build_view {
    my ($self) = @_;
    Blawd::View::TT2->new();
}

sub run {
    my $self = shift;
    say $self->git->all_sha1s;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Blawd - A class to ...

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
