package Blawd::Entry;
use Moose;
use namespace::autoclean;

has blob => ( is => 'ro' );
has directory_entry => ( is => 'ro', handles => ['filename'] );
has commit => ( is => 'ro' );

__PACKAGE__->meta->make_immutable;
1;
__END__
