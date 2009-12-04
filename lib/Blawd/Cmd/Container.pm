package Blawd::Cmd::Container;
use Moose;
use namespace::autoclean;

use Bread::Board;
use aliased 'Blawd::Renderer::RSS';
use Moose::Util::TypeConstraints qw(duck_type);
use List::MoreUtils qw(any uniq);

use Blawd::Index;

has config => (
    isa => duck_type( [qw(repo title)] ),
    is => 'ro',
    required => 1,
);

sub build_app {
    my ($self) = @_;
    my $cfg = $self->config;

    my $c = container Blawd => as {

        service gitdir => ( $cfg->repo );

        service title => ( $cfg->title );

        service headers => q[
	        <link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml" />
	        <link rel="openid.server" href="http://www.myopenid.com/server" />
	        <link rel="openid.delegate" href="http://openid.prather.org/chris" />
	    ];

        service app => (
            class        => 'Blawd',
            lifecycle    => 'Singleton',
            dependencies => [ depends_on('indexes'), depends_on('entries'), ]
        );

        service storage => (
            class        => 'Blawd::Storage::Git',
            dependencies => [ depends_on('gitdir'), ]
        );

        service entries => (
            block => sub {
                my $store = $_[0]->param('storage');
                [ sort { $b->date <=> $a->date } $store->find_entries ];
            },
            dependencies => [ depends_on('storage'), ],
        );

        service tags => (
            block => sub {
                [ uniq map { @{ $_->tags } } @{ $_[0]->param('entries') } ]
            },
            dependencies => [ depends_on('entries') ],
        );

        service indexes => (
            block => sub {
                my %common = (
                    title   => $_[0]->param('title'),
                    entries => $_[0]->param('entries')
                );
                return [
                    Blawd::Index->new(
                        filename => 'index',
                        headers  => $_[0]->param('headers'),
                        %common,
                    ),
                    Blawd::Index->new(
                        filename => 'rss',
                        renderer => RSS,
                        %common,
                    ),
                    map {
                        my $tag = $_;
                        Blawd::Index->new(
                            filename => $tag,
                            title    => $_[0]->param('title') . ': ' . $tag,
                            entries  => [ grep { $_->has_tag($tag) }
                                               @{ $_[0]->param('entries') } ],
                        )
                    } @{ $_[0]->param('tags') },
                ];
            },
            dependencies => [
                depends_on('title'), depends_on('entries'),
                depends_on('headers'), depends_on('tags'),
            ]
        );

    };

    return $c->fetch('app')->get;
}

1;
__END__
