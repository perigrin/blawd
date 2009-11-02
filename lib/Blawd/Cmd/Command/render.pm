package Blawd::Cmd::Command::render;
use 5.10.0;
use Moose;
use namespace::autoclean;
use Blawd;
extends qw(MooseX::App::Cmd::Command);
with qw(Blawd::Cmd::Container);

has title => ( isa => 'Str', is => 'ro', default => 'Blawd' );

has [qw(repo output_dir)] => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

sub run {
    my $self  = shift;
    my $blawd = $self->build_app($self);
    $_->render_to_file( $self->output_dir . '/' . $_->filename . $_->extension )
      for ( @{ $blawd->indexes }, @{ $blawd->entries } );
}

__PACKAGE__->meta->make_immutable;
1;
__END__
