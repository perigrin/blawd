package Blawd::Renderer::API;
use Blawd::OO::Role;
use MooseX::Types::Path::Class qw(File);

requires qw(render);

has extension => ( isa => 'Str', is => 'ro', default => '' );
has base_uri  => ( isa => 'Str', is => 'ro', default => '/' );

sub render_as_fragment { shift->render(@_) }

sub render_to_file {
    my ( $s, $f, @a ) = @_;
    to_File($f)->openw->print( $s->render(@a) );
}

1;
__END__
