package Blawd::Entry;
use Moose;
use namespace::autoclean;

with qw(Blawd::Renderable);

has blob => ( is => 'ro' );

has directory_entry => ( is => 'ro', handles => ['filename'] );

has commit => (
    isa     => 'Git::PurePerl::Object::Commit',
    is      => 'ro',
    handles => { mtime => 'committed_time' }
);

sub render { $_[0]->render_entry( $_[0] ) }

__PACKAGE__->meta->make_immutable;
1;
__END__
