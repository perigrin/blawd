package Blawd::Cmd::Command::server;
use Blawd::OO;
use HTTP::Engine;
use HTTP::Engine::Response;
use Plack::Loader;

sub abstract { q[Run a local webserver to serve blog files] }

extends qw(MooseX::App::Cmd::Command);

has repo => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    documentation => q[Location of the blog's data files],
);

has _http_engine => (
    isa        => 'HTTP::Engine',
    is         => 'ro',
    lazy_build => 1,
);

has host => (
    isa     => 'Str',
    is      => 'ro',
    default => 'localhost',
    documentation => q[Local host for the server to bind to],
);

has port => (
    isa     => 'Int',
    is      => 'ro',
    default => 1978,
    documentation => q[Local port for the server to bind to],
);

sub _build__http_engine {
    my ($self) = @_;
    HTTP::Engine->new(
        interface => {
            module          => 'PSGI',
            request_handler => sub { $self->handle_request(@_) },
        },
    );
}

sub execute {
    my $self = shift;
    my $app = sub { $self->_http_engine->run(@_) };
    Plack::Loader->auto( host => $self->host, port => $self->port )->run($app);
}

has container => (
    traits     => [qw(NoGetopt)],
    isa        => 'Blawd::Cmd::Container',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_container {
    my $self = shift;
    my $storage = Blawd::Storage->create_storage($self->repo);
    Blawd::Cmd::Container->new(storage => $storage);
}

sub handle_request {
    my ( $self, $req ) = @_;
    my $blawd = $self->container->build_app();
    my $renderer = $blawd->get_renderer('HTML');
    given ( $req->path ) {
        $_ =~ s|^/||;
        when ('site.css') {
            my $css = q[
				html { background-color: grey; }
				body{ 
					width: 900px; 
					background: white; 
					border: 1px solid black; 
					padding-left: 25px;
					padding-right: 25px;
				}
			];
            my $res = HTTP::Engine::Response->new( body => $css );
            $res->headers->header( Content_Type => 'text/css' );
            return $res;
        }
        $_ =~ s|\..*?$||;
        when ( $blawd->get_entry($_) ) {
            my $entry = $blawd->get_entry($_);
            return HTTP::Engine::Response->new(
                body => $renderer->render_page($entry)
            );
        }
        when ( $blawd->get_index($_) ) {
            my $index = $blawd->get_index($_);
            return HTTP::Engine::Response->new(
                body => $renderer->render_page($index)
            );
        }
        default {
            return HTTP::Engine::Response->new(
                body => $renderer->render_page($blawd->get_index('index'))
            );
        }
    }

}

__PACKAGE__->meta->make_immutable;
1;
__END__
