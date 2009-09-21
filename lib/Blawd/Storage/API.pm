package Blawd::Storage::API;
use Moose::Role;
use namespace::autoclean;

requires 'find_entries';

has entry_class => ( isa => 'Str', is => 'ro', default => 'Blawd::Entry' );

1;
__END__
