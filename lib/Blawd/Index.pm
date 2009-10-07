package Blawd::Index;
use Moose;
use DateTime;
use namespace::autoclean;

with qw(Blawd::Renderable);

has entries => (
    isa      => 'ArrayRef',
    traits   => ['Array'],
    required => 1,
    handles  => {
        entries => 'elements',
        size    => 'count',
    },
);

sub render_as_fragment { shift->content }

sub _build_author { 'Unknown' }
sub _build_date   { DateTime->now }

sub _build_content {
    join '', map { qq[<div class="entry">${\$_->render_as_fragment}</div>] }
      grep { defined $_ } shift->entries;
}

sub BUILD {
    my ( $self, $p ) = @_;

    my @entries = ( sort { $b->date cmp $a->date } @{ $p->{entries} } );
    @entries = @entries[ 0 .. 10 ] if @entries > 10;
    $self->meta->get_attribute('entries')->set_value( $self, \@entries );
}

with qw(Blawd::Entry::API);

1;
__END__
