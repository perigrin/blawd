package Blawd::Storage::API;
use Moose::Role;
use namespace::autoclean;
use Blawd::Entry::MultiMarkdown;

requires 'find_entries';

has renderer => ( isa => 'Str', is => 'ro', );

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
