use strict;
use MooseX::Declare;

class Blawed {

    use MooseX::Types::Path::Class qw(Dir);

    has directory => (
        isa      => Dir,
        is       => 'ro',
        coerce   => 1,
        required => 1
    );

    has git => (
        isa        => 'Git::PurePerl',
        is         => 'ro',
        lazy_build => 1,
    );

    method _build_git {
        Git::PurePerl->new( directory => $self->directory );
    }

    method run {
        confess $self->git->master->debug;
    }
}
