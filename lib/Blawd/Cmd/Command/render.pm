package Blawd::Cmd::Command::render;
use 5.10.0;
use Moose;
use namespace::autoclean;
use Blawd;
extends qw(MooseX::App::Cmd::Command);

has title => ( isa => 'Str', is => 'ro', default => 'Blawd' );

has [qw(repo output_dir)] => (
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

has blawd => (
    isa        => 'Blawd',
    is         => 'ro',
    lazy_build => 1
);

sub _build_blawd {
    my $self = shift;
    Blawd->new(
        title    => $self->title,
        repo     => $self->repo,
        renderer => $self->renderer,
    );
}

sub run {
    my $self = shift;
    $_->render_to_file( $self->output_dir . '/' . $_->filename . $_->extension )
      for ( @{ $self->blawd->indexes }, @{ $self->blawd->entries } );
}

__PACKAGE__->meta->make_immutable;
1;
__END__
