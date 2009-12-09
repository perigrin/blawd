package Blawd::Renderer::API;
use Blawd::OO::Role;
use MooseX::Types::Path::Class qw(File);

requires qw(render is_valid_entry);

sub render_as_fragment { shift->render(@_) }

sub render_to_file {
    my ( $s, $dir, $name, @a ) = @_;
    my $f = $dir . $name . $s->extension;
    to_File($f)->openw->print( $s->render(@a) );
}

# Stuff we just want to share

has render_factory => (
    isa      => 'Blawd::Renderer',
    handles  => ['get_renderer_for'],
    required => 1,
);

has extension => ( isa => 'Str', is => 'ro', default => '' );
has base_uri  => ( isa => 'Str', is => 'ro', default => '/' );
sub get_link_for { $_[0]->base_uri . $_[1]->filename . $_[0]->extension }

1;
__END__
