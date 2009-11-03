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
    required => 1
);

has container => (
    isa        => 'Blawd::Cmd::Container',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_container {
    Blawd::Cmd::Container->new( config => shift );
}

sub run {
    my $self  = shift;
    my $blawd = $self->container->build_app($self);
    $_->render_to_file( $self->output_dir . '/' . $_->filename . $_->extension )
      for ( @{ $blawd->indexes }, @{ $blawd->entries } );
}

__PACKAGE__->meta->make_immutable;
1;
__END__
