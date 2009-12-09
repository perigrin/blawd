package Blawd::Cmd::Container;
use Blawd::OO;
use Bread::Board;
use List::MoreUtils qw(uniq);

has storage => (
    is       => 'ro',
    does     => 'Blawd::Storage::API',
    required => 1,
);

sub build_app {
    my ($self) = @_;
    my $cfg = $self->storage->get_config;

    my $c = container Blawd => as {

        service title    => ( $cfg->{title}    || 'Blawd' );
        service base_uri => ( $cfg->{base_uri} || 'http://localhost/' );

        my $headers = <<'HEADERS';
<link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml" />
<link rel="alternate" type="application/atom+xml" title="Atom" href="atom.xml" />
HEADERS
        $headers .= $cfg->{headers} if exists $cfg->{headers};
        service headers => $headers;

        service footers => $cfg->{footers} // '';

        service app => (
            class        => 'Blawd',
            lifecycle    => 'Singleton',
            dependencies => [ depends_on('indexes'), depends_on('entries'), ]
        );

        service entries => (
            block => sub {
                [ sort { $b->date <=> $a->date } $self->storage->find_entries ];
            },
        );

        service tags => (
            block => sub {
                [ uniq map { @{ $_->tags } } @{ $_[0]->param('entries') } ];
            },
            dependencies => [ depends_on('entries') ],
        );
        service atom_renderer => (
            class        => 'Blawd::Renderer::Atom',
            dependencies => [ depends_on('base_uri') ],
        );
        service rss_renderer => (
            class        => 'Blawd::Renderer::RSS',
            dependencies => [ depends_on('base_uri') ],
        );
        service indexes => (
            block => sub {
                require Blawd::Index;
                my %common = (
                    title   => $_[0]->param('title'),
                    entries => [ @{ $_[0]->param('entries') }[ 0 ... 10 ] ],
                );
                return [
                    Blawd::Index->new(
                        filename => 'index',
                        headers  => $_[0]->param('headers'),
                        %common,
                    ),
                    Blawd::Index->new(
                        filename => 'rss',
                        renderer => $_[0]->param('rss_renderer'),
                        %common,
                    ),
                    Blawd::Index->new(
                        filename => 'atom',
                        renderer => $_[0]->param('atom_renderer'),
                        %common,
                    ),
                    map {
                        my $tag = $_;
                        Blawd::Index->new(
                            filename => $tag,
                            title    => $_[0]->param('title') . ': ' . $tag,
                            entries  => [
                                grep { $_->has_tag($tag) }
                                  @{ $_[0]->param('entries') }
                            ],
                          )
                      } @{ $_[0]->param('tags') },
                ];
            },
            dependencies => [
                depends_on('title'),        depends_on('atom_renderer'),
                depends_on('rss_renderer'), depends_on('entries'),
                depends_on('headers'),      depends_on('tags'),
            ]
        );

    };

    return $c->fetch('app')->get;
}

1;
__END__
