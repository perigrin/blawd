package Blawd;
use Moose 0.92;
use 5.10.0;
use namespace::autoclean;

our $VERSION = '0.01';

use Blawd::Storage::Git;
use Blawd::Index;
use MooseX::Types::Path::Class qw(Dir);

use aliased 'Blawd::Renderer::Simple';
use aliased 'Blawd::Renderer::RSS';

has title => ( isa => 'Str', is => 'ro', required => 1, );

has repo => (
    isa      => Dir,
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has init => ( isa => 'Bool', is => 'ro', );

has renderer => (
    isa     => 'Str',
    is      => 'ro',
    default => Simple,
);

has storage => (
    is         => 'ro',
    does       => 'Blawd::Storage::API',
    handles    => 'Blawd::Storage::API',
    lazy_build => 1,
);

sub _build_storage {
    my $self = shift;

    my %conf = (
        renderer => $self->renderer,
        gitdir   => $self->repo,
    );

    return Blawd::Storage::Git->init(%conf) if $self->init;
    return Blawd::Storage::Git->new(%conf);
}

has indexes => (
    isa        => 'ArrayRef[Blawd::Index]',
    is         => 'ro',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => {
        index      => [ 'get', '0' ],
        find_index => ['grep'],
    },
);

sub _build_indexes {
    my $self = shift;
    [
        Blawd::Index->new(
            title    => $self->title,
            filename => 'index',
            headers  => qq[<link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml" />
		    <link rel="openid.server" href="http://www.myopenid.com/server" />
		    <link rel="openid.delegate" href="http://openid.prather.org/chris" />		    
			],
            renderer => $self->renderer,
            entries  => $self->entries
        ),
        Blawd::Index->new(
            title    => $self->title,
            filename => 'rss',
            renderer => RSS,
            entries =>
              [ $self->find_entry( sub { $_->content =~ m/\bperl\b/; } ) ],
        )
    ];
}

sub get_index {
    my ( $self, $name ) = @_;
    my ($entry) = $self->find_index( sub { $_->filename eq $name } );
    return $entry;
}

has entries => (
    isa        => 'ArrayRef[Blawd::Entry::MultiMarkdown]',
    is         => 'ro',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => { find_entry => ['grep'], }
);

sub get_entry {
    my ( $self, $name ) = @_;
    my ($entry) = $self->find_entry( sub { $_->filename eq $name } );
    return $entry;
}

sub _build_entries {
    my ($self) = @_;
    [ $self->find_entries( $self->blawd_branch ) ];
}

sub refresh {
    my $self = shift;
    $self->clear_entries;
    $self->clear_indexes;
    $self->clear_storage;
    $self->storage;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
