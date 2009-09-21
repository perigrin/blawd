package Blawd::Storage::API;
use Moose::Role;
use namespace::autoclean;

requires 'find_entries';

has entry_class => (
    isa     => 'Str',
    is      => 'ro',
    builder => 'default_entry_class'
);

sub default_entry_class { 'Blawd::Entry' }

sub new_entry {
    shift->entry_class->new(@_);
}

1;
__END__
