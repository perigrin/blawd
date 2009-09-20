package Blawd::Index;
use Moose;
use namespace::autoclean;

with qw(Blawd::Renderable);

has _list => (
    isa      => 'ArrayRef[Blawd::Entry]',
    traits   => ['Array'],
    required => 1,
    init_arg => 'entries',
    handles  => { entries => 'sort', },
);

sub render {
    my ( $self, @entries ) = @_;
    $_->render for reverse $self->entries;
}

1;
__END__
