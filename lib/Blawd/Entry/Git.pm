package Blawd::Entry::Git;
use Moose;
use namespace::autoclean;
extends qw(Blawd::Entry);

has blob => ( is => 'ro' );

has directory_entry => ( is => 'ro', handles => ['filename'] );

has commit => (
    isa     => 'Git::PurePerl::Object::Commit',
    is      => 'ro',
    handles => { mtime => 'committed_time' }
);

1;
__END__
