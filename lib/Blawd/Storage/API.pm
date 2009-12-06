package Blawd::Storage::API;
use Blawd::OO::Role;

use YAML ();

requires 'find_entries', 'get_config', 'is_valid_location';

has location => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has entry_class => (
    isa     => 'Str',
    is      => 'ro',
    builder => 'default_entry_class'
);

sub default_entry_class {
    'Blawd::Entry::MultiMarkdown';
}

sub new_entry {
    my $entry_class = shift->entry_class;
    Class::MOP::load_class($entry_class);
    $entry_class->new(@_);
}

sub parse_config {
    my $self = shift;
    my ($cfg_data) = @_;
    my @parsed_cfg = YAML::Load($cfg_data);
    if (@parsed_cfg != 1 || reftype($parsed_cfg[0]) ne 'HASH') {
        die "Config must be a hash";
    }

    return $parsed_cfg[0];
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
