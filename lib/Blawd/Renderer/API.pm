package Blawd::Renderer::API;
use Moose::Role;
use namespace::autoclean;

requires qw(render);

has css => ( isa => 'Str', is => 'ro', default => 'site.css' );

1;
__END__
