package Blawd::View::Test;
use Moose;
use 5.10.0;
use namespace::autoclean;

with qw(Blawd::View::API);

sub render_entry {
    my ( $self, $entry ) = @_;
    say $entry->{commit}->author->name . ' - '
      . $entry->{commit}->committed_time;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
