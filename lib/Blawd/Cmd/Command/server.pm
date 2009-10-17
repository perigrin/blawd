package Blawd::Cmd::Command::server;
use 5.10.0;
use Moose;
use namespace::autoclean;
use Blawd;
use HTTP::Engine;
use HTTP::Engine::Response;

extends qw(MooseX::App::Cmd::Command);

has repo => (
    isa      => 'Str',
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has renderer => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Blawd::Renderer::MultiMarkdown',
);

has blawd => (
    isa        => 'Blawd',
    is         => 'ro',
    lazy_build => 1
);

sub _build_blawd {
    my $self = shift;
    Blawd->new(
        repo       => $self->repo,
        renderer   => $self->renderer,
    );
}

has _http_engine => (
    isa        => 'HTTP::Engine',
    is         => 'ro',
    lazy_build => 1,
    handles    => [qw(run)],
);

has host => ( isa => 'Str', is => 'ro', default => 'localhost' );
has port => ( isa => 'Int', is => 'ro', default => 1978 );

sub _build__http_engine {
    my ($self) = @_;
    HTTP::Engine->new(
        interface => {
            module => 'ServerSimple',
            args   => {
                host => $self->host,
                port => $self->port,
            },
            request_handler => sub { $self->handle_request(@_) },
        },
    );
}

sub handle_request {
    my ( $self, $req ) = @_;
    HTTP::Engine::Response->new( body => $self->blawd->index->render );
}

__PACKAGE__->meta->make_immutable;
1;
__END__
