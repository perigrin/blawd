package Blawd::Renderer::API;
use Blawd::OO::Role;
use MooseX::Types::Path::Class qw(File);

requires qw(render_page extension);

has base_uri  => ( isa => 'Str', is => 'ro', default => '/' );

sub render_fragment { shift->render_page(@_) }

sub render_to_file {
    my ( $s, $f, @a ) = @_;
    to_File($f)->openw->print( $s->render_page(@a) );
}

1;
__END__
