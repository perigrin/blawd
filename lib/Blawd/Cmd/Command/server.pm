package Blawd::Cmd::Command::server;
use 5.10.0;
use Moose;
use namespace::autoclean;
use Blawd;
use HTTP::Engine;
use HTTP::Engine::Response;
use MooseX::Types::Path::Class qw(File);
extends qw(MooseX::App::Cmd::Command);

has title => ( isa => 'Str', is => 'ro', default => 'Blawd' );

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
        title    => $self->title,
        repo     => $self->repo,
        renderer => $self->renderer,
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

has css => (
    isa       => File,
    is        => 'ro',
    predicate => 'has_css',
    coerce    => 1,
);

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
    given ( $req->path ) {
        $_ =~ s|^/||;
        when ( $self->blawd->get_entry($_) ) {
            my $entry = $self->blawd->get_entry($_);
            return HTTP::Engine::Response->new( body => $entry->render );
        }
        when ( $self->blawd->get_index($_) ) {
            my $index = $self->blawd->get_index($_);
            return HTTP::Engine::Response->new( body => $index->render );
        }
        when ('site.css') {
            my $css = $self->has_css ? $self->css->slurp : q[
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
        default {
            return HTTP::Engine::Response->new(
                body => $self->blawd->get_index('index')->render );
        }
    }

}

__PACKAGE__->meta->make_immutable;
1;
__END__
