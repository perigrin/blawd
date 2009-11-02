package Blawd::Cmd::Command::server;
use 5.10.0;
use Moose;
use namespace::autoclean;
use HTTP::Engine;
use HTTP::Engine::Response;

extends qw(MooseX::App::Cmd::Command);
with qw(Blawd::Cmd::Container);

has title => ( isa => 'Str', is => 'ro', default => 'Blawd' );

has repo => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

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
    my $blawd = $self->build_app($self);
    given ( $req->path ) {
        $_ =~ s|^/||;
        when ( $blawd->get_entry($_) ) {
            my $entry = $blawd->get_entry($_);
            return HTTP::Engine::Response->new( body => $entry->render );
        }
        when ( $blawd->get_index($_) ) {
            my $index = $blawd->get_index($_);
            return HTTP::Engine::Response->new( body => $index->render );
        }
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
        default {
            return HTTP::Engine::Response->new(
                body => $blawd->get_index('index')->render );
        }
    }

}

__PACKAGE__->meta->make_immutable;
1;
__END__
