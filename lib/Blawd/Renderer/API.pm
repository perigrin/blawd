package Blawd::Renderer::API;
use Blawd::OO::Role;

requires qw(render);

has css       => ( isa => 'Str', is => 'ro', default => 'site.css' );
has extension => ( isa => 'Str', is => 'ro', default => '' );

1;
__END__
