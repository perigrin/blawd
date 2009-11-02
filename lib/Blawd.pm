package Blawd;
use Moose 0.92;
use 5.10.0;
use namespace::autoclean;

our $VERSION = '0.01';

use Blawd::Storage::Git;
use Blawd::Index;
use MooseX::Types::Path::Class qw(Dir);

has title => ( isa => 'Str', is => 'ro', required => 1, );

has indexes => (
    isa     => 'ArrayRef[Blawd::Index]',
    is      => 'ro',
    traits  => ['Array'],
    handles => {
        index      => [ 'get', '0' ],
        find_index => ['grep'],
    },
    required => 1,
);

sub get_index {
    my ( $self, $name ) = @_;
    return unless $name;
    my ($idx) = $self->find_index( sub { $_->filename eq $name } );
    return $idx;
}

has entries => (
    isa      => 'ArrayRef[Blawd::Entry::MultiMarkdown]',
    is       => 'ro',
    traits   => ['Array'],
    handles  => { find_entry => ['grep'], },
    required => 1,
);

sub get_entry {
    my ( $self, $name ) = @_;
    return unless $name;
    my ($entry) = $self->find_entry( sub { $_->filename eq $name } );
    return $entry;
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
