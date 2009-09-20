package  Blawd;
use Moose;
use 5.10.0;

use MooseX::Types::Path::Class qw(Dir);
use Git::PurePerl;
use namespace::autoclean;
use MooseX::Getopt;

has directory => (
    isa      => Dir,
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has git => (
    isa        => 'Git::PurePerl',
    is         => 'ro',
    traits     => ['NoGetopt'],
    lazy_build => 1,
);

sub _build_git {
    my $self = shift;
    Git::PurePerl->new( directory => $self->directory );
}

sub run {
    my $self = shift;
    say $self->git->all_sha1s;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
