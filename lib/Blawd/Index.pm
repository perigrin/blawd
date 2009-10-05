package Blawd::Index;
use Moose;
use namespace::autoclean;

with qw(Blawd::Renderable);

has _list => (
    isa      => 'ArrayRef',
    traits   => ['Array'],
    required => 1,
    init_arg => 'entries',
    handles  => {
        entries => 'elements',
        size    => 'count',
    },
);

sub render_as_fragment {
    join '', map { qq[<div class="entry">${\$_->render_as_fragment}</div>] }
      grep { defined $_ } $_[0]->entries;
}

sub content {
    return shift->render_as_fragment;
}

sub BUILD {
    my ( $self, $p ) = @_;

    my @entries = ( sort { $b->date cmp $a->date } @{ $p->{entries} } );
    @entries = @entries[ 0 .. 10 ] if @entries > 10;

    $self->meta->get_attribute('_list')->set_value( $self, \@entries );
}

1;
__END__
