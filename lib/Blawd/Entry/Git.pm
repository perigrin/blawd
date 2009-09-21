package Blawd::Entry::Git;
use Moose;
use namespace::autoclean;

has blob => ( is => 'ro', handles => ['content'] );

has directory_entry => ( is => 'ro', handles => ['filename'] );

has commit => (
    isa     => 'Git::PurePerl::Object::Commit',
    is      => 'ro',
    handles => {
        mtime => 'committed_time',
        ctime => 'authored_time',
    }
);

with qw(Blawd::Entry::API);

__PACKAGE__->meta->make_immutable;
1;
__END__
