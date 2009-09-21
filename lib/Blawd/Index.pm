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
        entries => 'sort',
        size    => 'count',
    },
);

1;
__END__
