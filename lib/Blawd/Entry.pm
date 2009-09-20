package Blawd::Entry;
use Moose;
use namespace::autoclean;

has blob   => ( is => 'ro' );
has commit => ( is => 'ro' );

__PACKAGE__->meta->make_immutable;
1;
__END__
