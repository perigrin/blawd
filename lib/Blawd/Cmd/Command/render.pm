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

has init => ( isa => 'Bool', is => 'ro', );

has renderer => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Blawd::Renderer::Simple',
);

has blawd => ( isa => 'Str', is => 'ro', );

sub run {
    my $self = shift;
    say Blawd->new(
        repo     => $self->repo,
        init     => $self->init,
        renderer => $self->renderer,
    )->index->render;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
