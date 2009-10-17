package Blawd::Renderer::API;
use Moose::Role;
use namespace::autoclean;

requires qw(render);

has css       => ( isa => 'Str', is => 'ro', default => 'site.css' );
has extension => ( isa => 'Str', is => 'ro', default => '' );

1;
__END__
