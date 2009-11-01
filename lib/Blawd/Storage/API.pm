package Blawd::Storage::API;
use Moose::Role;
use namespace::autoclean;
use Blawd::Entry::MultiMarkdown;

requires 'find_entries';

sub blawd_branch { return shift->master }

has entry_class => (
    isa     => 'Str',
    is      => 'ro',
    builder => 'default_entry_class'
);

sub default_entry_class {
    'Blawd::Entry::MultiMarkdown';
}

sub new_entry {
    shift->entry_class->new(@_);
}

1;
__END__

=head1 NAME

Blawd::Storage::API - A interface for Blawd Storage Classes

=head1 SYNOPSIS

	package Blawd::Storage::Git;
	use Moose;
	with qw(Blawd::Storage::API);

=head1 DESCRIPTION

The Blawd::Storage::API Role implements an interface for Blawd Storage
Classes

=head1 METHODS

=head2 blawd_branch

The Branch that this Blawd instance renders from.

=head2 default_entry_class

Default entry storage type. Currently defaults to
L<Blawd::Entry::Markdown|Blawd::Entry::Markdown>.

=head2 new_entry

Creates a new entry instance based on the class name in
C<default_entry_class>.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
