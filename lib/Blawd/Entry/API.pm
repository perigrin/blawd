package Blawd::Entry::API;
use Moose::Role;
use namespace::autoclean;

with qw( Blawd::Renderable );

requires qw(
  author
  filename
  content
  date
);

1;
__END__
