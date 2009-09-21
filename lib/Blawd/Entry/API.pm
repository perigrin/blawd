package Blawd::Entry::API;
use Moose::Role;
use namespace::autoclean;

with qw( Blawd::Renderable );
requires qw(
  author
  filename
  content
  mtime
  ctime
);
sub render { $_[0]->render_entry( $_[0] ) }

1;
__END__
