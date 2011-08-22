package Blawd::Cmd::Command::server;
use 5.10.0;
use Blawd::OO;
use Plack::Loader;
use Plack::Request;
use Plack::Response;

sub abstract { q[Run a local webserver to serve blog files] }

extends qw(MooseX::App::Cmd::Command);

has repo => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    documentation => q[Location of the blog's data files],
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

sub execute {
    my $self = shift;
    say "Starting up server on http://${\$self->host}:${\$self->port}";
    Plack::Loader->auto(
        host => $self->host,
        port => $self->port,
    )->run(
        sub {
            my $req = Plack::Request->new(@_);
            my $res = $self->handle_request($req);
            return $res->finalize;
        }
    );
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
    my $res = Plack::Response->new(200, { Content_Type => 'text/html' });
    given ( $req->path ) {
        $_ =~ s|^/||;
        when ('site.css') {
            my $css = q[
                html {
                    background-color: grey;
                }
                body {
                    width: 900px;
                    background: white;
                    border: 1px solid black;
                    padding-left: 25px;
                    padding-right: 25px;
                }
            ];
            $res->content_type('text/css');
            $res->body($css);
            return $res;
        }
        $_ =~ s|\..*?$||;
        when ( $blawd->get_entry($_) ) {
            my $entry = $blawd->get_entry($_);
            $res->body($renderer->render_page($entry));
            return $res;
        }
        when ( $blawd->get_index($_) ) {
            my $index = $blawd->get_index($_);
            $res->body($renderer->render_page($index));
            return $res;
        }
        default {
            $res->body($renderer->render_page($blawd->get_index('index')));
            return $res;
        }
    }

}

__PACKAGE__->meta->make_immutable;
1;
__END__
