#!/usr/bin/perl 
use strict;
use Test::More;
use Test::Deep;

use Try::Tiny;
use Path::Class;
use Blawd;

use aliased 'Blawd::Cmd::Container';
use aliased 'Blawd::Storage';

BEGIN {
    try { use Git::Wrapper }
    catch { plan skip_all => 'Tests Require Git::Wrapper ' };
}

my $directory = 'my-blog';
dir($directory)->rmtree;
dir($directory)->mkpath;

my $g = Git::Wrapper->new($directory);
$g->init;

my $hello = dir($directory)->file('hello');
$hello->openw->print('Hello World');
$g->add('hello');
my $cfg = dir($directory)->file('.blawd');
$cfg->openw->print("---\ntitle: Blawd\n");
$g->add('.blawd');
$g->commit( { message => 'first post' } );

my $storage = Storage->create_storage("$directory/.git");
ok( my $blog = Container->new( storage => $storage )->build_app );

ok( my @entries = $blog->entries, 'got entries' );
is( @entries, 1, 'only one entry' );

ok( $_->does('Blawd::Entry::API'), 'does Blawd::Entry::API' ) for @entries;
is(
    $entries[0]->date,
    DateTime->from_epoch(
        epoch     => $hello->stat->mtime,
        time_zone => 'America/New_York'
    ),
    'right mtime'
);

my ($author) = $g->config('user.name');
is( $entries[0]->author,  $author,       'right author' );
is( $entries[0]->content, 'Hello World', 'right content' );
like(
    $entries[0]->render_fragment_HTML,
    qr"<pre>\nHello World\n",
    'render correctly'
);

isa_ok( $blog->index, 'Blawd::Index' );
ok( my $renderer = $blog->get_renderer('HTML'), 'got renderer' );
like(
    $blog->index->render_fragment_HTML($renderer),
    qr"<pre>\nHello World\n",
    'index renders'
);

my $bye = dir($directory)->file('goodbye');
$bye->openw->print('Goodbye World');
$g->add('goodbye');
$g->commit( { message => 'second post' } );

$blog = Container->new( storage => $storage )->build_app;
ok( @entries = $blog->entries, 'got entries' );
is( scalar @entries, 2, 'got two entries' );
ok( $_->does('Blawd::Entry::API'), 'does Blawd::Entry::API' ) for @entries;

# is( $entries[-1]->date, DateTime->from_epoch( epoch => $hello->stat->mtime, ),
#     'right mtime' );
is( $entries[-1]->author,  $author,       'right author' );
is( $entries[-1]->content, 'Hello World', 'right content' );
like(
    $entries[-1]->render_fragment_HTML,
    qr"<pre>\nHello World\n",
    'render correctly'
);

# is( $entries[0]->date, DateTime->from_epoch( epoch => $bye->stat->mtime, ),
#     'right mtime' );
is( $entries[0]->author,  $author,         'right author' );
is( $entries[0]->content, 'Goodbye World', 'right content' );
like(
    $entries[0]->render_fragment_HTML,
    qr"<pre>\nGoodbye World\n",
    'render correctly'
);

#$blog = Container->new( config => Config->new )->build_app;
isa_ok( $blog->index, 'Blawd::Index' );
is( $blog->index->size, 2, 'index is the right size' );
like(
    $blog->get_index('index')->render_fragment_HTML($renderer),
    qr|<div class="entry">\n<pre>\nGoodbye World|m,
    'index renders'
);

is_deeply( $entries[0], $blog->get_entry('goodbye'), 'entry compares okay' );

for ( 3 .. 15 ) {
    my $post = dir($directory)->file( 'lorem' . $_ );
    $post->openw->print(<<"END_POST");
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
occaecat cupidatat non proident, sunt in culpa qui officia deserunt
mollit anim id est laborum.

END_POST

    $g->add( 'lorem' . $_ );
    $g->commit( { message => 'lorem post ' . $_ } );
}

$blog = Container->new( storage => $storage )->build_app;
isa_ok( $blog->get_index('index'), 'Blawd::Index' );
is( $blog->get_index('index')->size, 10, 'index is the right size' );
like(
    $blog->get_index('index')->render_fragment_HTML($renderer),
    qr|<div class="entry">\n<pre>\nLorem|m,
    'index renders'
);
like(
    ( $blog->entries )[-1]->render_fragment_HTML,
    qr"<pre>\nLorem",
    'render correctly'
);

{
    my $renderer = $blog->get_renderer('RSS');
    die "couldn't find RSS renderer" unless $renderer;
    ok( my $rss = $blog->get_index('index')->render_page_default($renderer),
        'got RSS' );
    is( $blog->get_index('index')->render_page_default($renderer),
        $rss, 'fragment is the full RSS' );

    # ok( $blog->get_index('rss')->render_to_file('/tmp/blawd_test_rss'),
    #     'render to file' );
    # is( file('/tmp/blawd_test_rss')->slurp, $rss, 'file output is good' );
}
done_testing;
dir($directory)->rmtree;
file('/tmp/blawd_test_rss')->remove;
