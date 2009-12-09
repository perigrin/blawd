package Blawd::Page;
use Blawd::OO::Role;

has title => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has [
    qw(
      content
      filename
      )
  ] => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
  );

requires qw(_build_title);

1;
__END__
