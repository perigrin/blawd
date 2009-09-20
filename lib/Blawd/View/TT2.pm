package Blawd::View::TT2;
use Moose;
use namespace::autoclean;

with qw(Blawd::View::API);

use Template;

has config => (
    isa        => 'HashRef',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_config {
    my ($self) = @_;
}

has template => (
    isa        => 'Template',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_template {
    my ($self) = @_;
    Template->new( $self->config );
}

sub render_entry {
    my ( $self, $template, $data ) = @_;

    $self->template->process( $template, $data )
      || confess $self->template->error();
}

__PACKAGE__->meta->make_immutable;
1;
__END__
