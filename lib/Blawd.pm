package Blawd;
use Moose 0.92;
use 5.10.0;
use namespace::autoclean;

our $VERSION = '0.01';

use Blawd::Storage::Git;
use Blawd::Index;
use MooseX::Types::Path::Class qw(Dir);

has [qw(repo)] => (
    isa      => Dir,
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has init => ( isa => 'Bool', is => 'ro', );

has renderer => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Blawd::Renderer::Simple',
);

has storage => (
    is         => 'ro',
    does       => 'Blawd::Storage::API',
    handles    => 'Blawd::Storage::API',
    lazy_build => 1,
);

sub _build_storage {
    my $self = shift;

    my %conf = (
        renderer => $self->renderer,
        gitdir   => $self->repo,
    );

    return Blawd::Storage::Git->init(%conf) if $self->init;
    return Blawd::Storage::Git->new(%conf);
}

has indexes => (
    isa        => 'ArrayRef[Blawd::Index]',
    is         => 'ro',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => { index => [ 'get', '0' ] },
);

sub _build_indexes {
    my $self = shift;
    [
        Blawd::Index->new(
            filename => '/index.html',
            renderer => $self->renderer,
            entries  => $self->entries
        )
    ];
}

has entries => (
    isa        => 'ArrayRef[Blawd::Entry::MultiMarkdown]',
    is         => 'ro',
    lazy_build => 1,
);
use Data::Dumper;

sub _build_entries {
    my ($self) = @_;
    [ $self->find_entries( $self->blawd_branch ) ];
}

sub refresh {
    my $self = shift;
    $self->clear_entries;
    $self->clear_indexes;
    $self->clear_storage;
    $self->storage;
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
