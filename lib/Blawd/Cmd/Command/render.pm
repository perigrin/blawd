package Blawd::Cmd::Command::render;
use Blawd::OO;
extends qw(MooseX::App::Cmd::Command);

use Blawd::Storage;
use Blawd::Cmd::Container;

sub abstract { q[Render blog as static HTML files] }

has repo => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    documentation => q[Location of the blog's data files],
);

has output_dir => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    documentation => q[Location to put the rendered output],
);

has container => (
    traits     => [qw(NoGetopt)],
    isa        => 'Blawd::Cmd::Container',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_container {
    my $self = shift;
    my $storage = Blawd::Storage->create_storage($self->repo);
    Blawd::Cmd::Container->new(storage => $storage);
}

sub execute {
    my $self  = shift;
    my $blawd = $self->container->build_app;
    $blawd->render_all($self->output_dir);
}

__PACKAGE__->meta->make_immutable;
1;
__END__
