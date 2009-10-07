package Blawd::Cmd::Command::render;
use 5.10.0;
use Moose;
use namespace::autoclean;
use Blawd;
extends qw(MooseX::App::Cmd::Command);

has repo => (
    isa      => 'Str',
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has renderer => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Blawd::Renderer::MultiMarkdown',
);

has blawd => ( isa => 'Str', is => 'ro', );

has output => (
    isa        => 'IO::Handle',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_output {
    my ($self) = @_;
    my $io = IO::Handle->new;
    $io->fdopen( fileno(STDOUT), 'w' );
    return $io;
}

sub run {
    my $self = shift;
    $self->output->say(
        Blawd->new(
            repo     => $self->repo,
            renderer => $self->renderer,
          )->index->render
    );
}

__PACKAGE__->meta->make_immutable;
1;
__END__
