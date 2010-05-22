package Blawd::Exporter::DB;

use Blawd::OO::Role;
use DBI;

has entry_query => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has [qw(db host port user pass)] =>
  ( isa => 'Str', is => 'ro', lazy_build => 1 );
sub _build_db   { '' }
sub _build_host { '127.0.01' }
sub _build_port { 3306 }
sub _build_user { $ENV{USER} }
sub _build_pass {''}

requires qw/_build_entry_query dsn/;

has dbi => (
    is         => 'ro',
    traits     => ['NoGetopt'],
    lazy_build => 1,
);

sub _build_dbi {
    my ($self) = @_;
    DBI->connect($self->dsn, $self->user, $self->pass);
}

1;
__END__
