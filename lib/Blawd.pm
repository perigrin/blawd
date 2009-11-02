package Blawd;
use Moose 0.92;
use 5.10.0;
use namespace::autoclean;

our $VERSION = '0.01';

use Blawd::Storage::Git;
use Blawd::Index;
use MooseX::Types::Path::Class qw(Dir);

use aliased 'Blawd::Renderer::RSS';

has title => ( isa => 'Str', is => 'ro', required => 1, );

has repo => (
    isa      => Dir,
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has init => ( isa => 'Bool', is => 'ro', );

has storage => (
    is         => 'ro',
    does       => 'Blawd::Storage::API',
    handles    => 'Blawd::Storage::API',
    lazy_build => 1,
);

sub _build_storage {
    my $self = shift;

    my %conf = ( gitdir => $self->repo, );

    return Blawd::Storage::Git->init(%conf) if $self->init;
    return Blawd::Storage::Git->new(%conf);
}

has headers => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_headers {
    my ($self) = @_;
qq[<link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml" />
    <link rel="openid.server" href="http://www.myopenid.com/server" />
    <link rel="openid.delegate" href="http://openid.prather.org/chris" />		    
	]
}

has indexes => (
    isa        => 'ArrayRef[Blawd::Index]',
    is         => 'ro',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => {
        index      => [ 'get', '0' ],
        find_index => ['grep'],
    },
);

sub _build_indexes {
    my $self = shift;
    [
        Blawd::Index->new(
            title    => $self->title,
            filename => 'index',
            headers  => $self->headers,
            entries  => $self->entries
        ),
        Blawd::Index->new(
            filename => 'rss',
            renderer => RSS,
            entries  => $self->entries,
        )
    ];
}

sub get_index {
    my ( $self, $name ) = @_;
    my ($entry) = $self->find_index( sub { $_->filename eq $name } );
    return $entry;
}

has entries => (
    isa        => 'ArrayRef[Blawd::Entry::MultiMarkdown]',
    is         => 'ro',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => { find_entry => ['grep'], }
);

sub _build_entries {
    my ($self) = @_;
    [ sort { $b->date <=> $a->date }$self->find_entries() ];
}

sub get_entry {
    my ( $self, $name ) = @_;
    my ($entry) = $self->find_entry( sub { $_->filename eq $name } );
    return $entry;
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

__END__

=head1 NAME

Blawd - A class to ...

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

use Blawd;

=head1 DESCRIPTION

The Blawd class implements ...

=head1 METHODS

=head2 get_index (Str $name)

Retrieves the named index.

=head2 get_entry (Str $name)

Retrieves the named entry

=head2 refresh ()

Reload data from the source Git repository.

=description PRIVATE METHDOS

=head2 _build_storage (method)

=head2 _build_indexes

=head2 _build_entries (method)

=head1 DEPENDENCIES

=over

=item aliased

=item DateTime

=item Git::PurePerl

=item Memoize

=item Moose

=item MooseX::Types::DateTime

=item MooseX::Types::DateTimeX

=item MooseX::Types::Path::Class

=item namespace::autoclean

=item Path::Class

=item Text::MultiMarkdown

=item Try::Tiny

=item XML::RSS

=back

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
