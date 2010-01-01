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

        service title    => ( $cfg->{title}    || 'The Room' );
        service base_uri => ( $cfg->{base_uri} || 'http://chris.prather.org/' );

        my $headers = <<'HEADERS';
<link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml" />
<link rel="alternate" type="application/atom+xml" title="Atom" href="atom.xml" />
  <link rel="openid.server"
        href="http://www.myopenid.com/server" />
  <link rel="openid.delegate"
        href="http://openid.prather.org/chris" />
  <link rel="openid2.local_id"
        href="http://openid.prather.org/chris" />
  <link rel="openid2.provider"
        href="http://www.myopenid.com/server" />
  <meta http-equiv="X-XRDS-Location"
        content="http://www.myopenid.com/xrds?username=openid.prather.org/chris" />
HEADERS
        $headers .= $cfg->{headers} if exists $cfg->{headers};
        service headers => $headers;

        service footers => $cfg->{footers} // <<'FOOTERS';
<script type="text/javascript">
        try {
            var pageTracker = _gat._getTracker("UA-939082-2");
            pageTracker._trackPageview();
        } catch(err) {}
</script>
FOOTERS

        service app => (
            class        => 'Blawd',
            lifecycle    => 'Singleton',
            dependencies => [
                depends_on('indexes'), depends_on('entries'),
                depends_on('render_factory')
            ]
        );

        service entries => (
            block => sub {
                [
                    sort  { $b->date <=> $a->date }
                      map { Blawd::Entry->new_entry($_) }
                      $self->storage->find_entries
                ];
            },
        );

        service tags => (
            block => sub {
                [ uniq map { @{ $_->tags } } @{ $_[0]->param('entries') } ];
            },
            dependencies => [ depends_on('entries') ],
        );

        service render_factory => (
            class        => 'Blawd::Renderer',
            lifecycle    => 'Singleton',
            dependencies => [
                depends_on('base_uri'), depends_on('headers'),
                depends_on('footers'),
            ],
        );

        service indexes => (
            block => sub {
                require Blawd::Index;
                return [
                    Blawd::Index->new(
                        filename       => 'index',
                        title          => $_[0]->param('title'),
                        render_factory => $_[0]->param('render_factory'),
                        entries => [ @{ $_[0]->param('entries') }[ 0 ... 10 ] ],
                    ),
                    Blawd::Index->new(
                        filename       => 'rss',
                        title          => $_[0]->param('title'),
                        render_factory => $_[0]->param('render_factory'),
                        entries => [ @{ $_[0]->param('entries') }[ 0 ... 10 ] ],
                    ),
                    Blawd::Index->new(
                        filename       => 'atom',
                        title          => $_[0]->param('title'),
                        render_factory => $_[0]->param('render_factory'),
                        entries => [ @{ $_[0]->param('entries') }[ 0 ... 10 ] ],
                    ),
                    map {
                        my $tag = $_;
                        Blawd::Index->new(
                            filename => $tag,
                            title    => $_[0]->param('title') . ': ' . $tag,
                            render_factory => $_[0]->param('render_factory'),
                            entries        => [
                                grep { $_->has_tag($tag) }
                                  @{ $_[0]->param('entries') }
                            ],
                          )
                      } @{ $_[0]->param('tags') },
                ];
            },
            dependencies => [
                depends_on('title'), depends_on('entries'),
                depends_on('tags'),  depends_on('render_factory'),
            ]
        );

    };

    return $c->fetch('app')->get;
}

1;
__END__
