package Blawd::Entry::API;
use Moose::Role;
use MooseX::Types::DateTime qw(DateTime);
use namespace::autoclean;

with qw( Blawd::Renderable );

has author => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has date => (
    isa        => DateTime,
    is         => 'ro',
    coerce     => 1,
    lazy_build => 1
);

has content => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has filename => ( isa => 'Str', is => 'ro', required => 1, );

requires qw(
  _build_author
  _build_date
  _build_content
);

1;
__END__
