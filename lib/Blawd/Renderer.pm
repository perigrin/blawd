package Blawd::Renderer;
use Moose;
use namespace::clean -except => 'meta';

use Module::Pluggable (
    require     => 1,
    sub_name    => 'renderer_classes',
    search_path => [__PACKAGE__],
    except      => qr/Meta|Role|API/,
);

sub determine_renderer_class {
    my $class = shift;
    my ($entry) = @_;

    for my $renderer_class ( $class->renderer_classes ) {
        return $renderer_class if $renderer_class->is_valid_entry($entry);
    }
    return;
}

has base_uri => ( isa => 'Str', is => 'ro', required => 1 );
has headers  => ( isa => 'Str', is => 'ro', required => 1 );
has footers  => ( isa => 'Str', is => 'ro', required => 1 );

sub get_renderer_for {
    my ( $self, $entry ) = @_;
    my $class = $self->determine_renderer_class($entry);
    return $class->new(
        base_uri       => $self->base_uri,
        headers        => $self->headers,
        footers        => $self->footers,
        render_factory => $self,
    );
}

1;
__END__
