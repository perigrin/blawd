package Blawd::Entry;
use Moose;
use namespace::autoclean;

with qw(	Blawd::Renderable );

sub render { $_[0]->render_entry( $_[0] ) }

__PACKAGE__->meta->make_immutable;
1;
__END__
