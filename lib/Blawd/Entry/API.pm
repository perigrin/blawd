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

1;
__END__
