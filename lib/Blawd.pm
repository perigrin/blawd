package Blawd;
use Moose 0.90;
use 5.10.0;
use namespace::autoclean;

our $VERSION = '0.01';

use Blawd::Storage::Git;
use Blawd::Index;
use MooseX::Types::Path::Class qw(Dir);

has repo => (
    isa      => Dir,
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has init => ( isa => 'Bool', is => 'ro', );

has _storage => (
    is         => 'ro',
    does       => 'Blawd::Storage::API',
    handles    => 'Blawd::Storage::API',
    lazy_build => 1,
);

sub _build__storage {
    my $self = shift;
    return Blawd::Storage::Git->init( gitdir => $self->repo ) if $self->init;
    return Blawd::Storage::Git->new( gitdir => $self->repo );
}

has _index => (
    is         => 'ro',
    isa        => 'Blawd::Index',
    handles    => 'Blawd::Renderable',
    lazy_build => 1,
);

sub _build__index {
    Blawd::Index->new( entries => [ shift->find_entries ] );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Blawd - A Quick and Dirty Blogging System

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

	use Blawd;
	Blawd->new( gitdir => '/var/git/repositories/myblog.git' );

=head1 DESCRIPTION

Blawd is in it's infancy. The basic idea is to take MultiMarkdown files stored
in a git revisioned tree, combine them with some Template Toolkit templates
and generate a blog. Mostly I'm looking for an excuse to play with
Git::PurePerl, and learn the git internals better.

=head1 ATTRIBUTES

=head2 repo 

The directory that your Blog Repo lives in. Currently this is expecting a Git
Repo.

=head2 init

Create a new Git Repo (at the value of repo) to hold the Blog.

=head1 METHODS

=head2 render (method)

Render the current index or entry.

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
