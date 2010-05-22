package Blawd::Exporter;

use Blawd::OO::Role;

use Path::Class;
use Git::Wrapper;

requires qw/abstract/;

has author => (isa => 'Str', is => 'ro',);
has git => (isa => 'Git::Wrapper', is => 'ro', lazy_build => 1,);
has repo => (
    isa      => 'Str',
    is       => 'ro',
    coerce   => 1,
    required => 1
);

sub _build_git {
    my $self = shift;
    Git::Wrapper->new($self->repo);
}

before execute => sub {
    my $self = shift;
    unless (-d $self->repo) {
        dir($self->repo)->mkpath;
        $self->git->init;
    }
};

after execute => sub {
    my $self  = shift;
    $self->git->commit( { message => "import blog" } );
};

1;
__END__
