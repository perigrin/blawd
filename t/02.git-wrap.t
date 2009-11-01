#!/usr/bin/perl 
use strict;
use Test::More;
use Test::Deep;

use Try::Tiny;
use Path::Class;
use Blawd;

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
$g->commit( { message => 'first post' } );

ok( my $blog = Blawd->new( repo => "$directory/.git", title => 'test' ),
    'new blawd' );

ok( my @entries = $blog->find_entries, 'got entries' );
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
is( $entries[0]->author,  'Chris Prather', 'right author' );
is( $entries[0]->content, 'Hello World',   'right content' );
like(
    $entries[0]->render_as_fragment,
    qr"<p>Hello World\n",
    'render correctly'
);

isa_ok( $blog->index, 'Blawd::Index' );
like( $blog->index->render, qr"<p>Hello World\n", 'index renders' );

my $bye = dir($directory)->file('goodbye');
$bye->openw->print('Goodbye World');
$g->add('goodbye');
$g->commit( { message => 'second post' } );

ok( my @entries = $blog->find_entries, 'got entries' );
ok( $_->does('Blawd::Entry::API'), 'does Blawd::Entry::API' ) for @entries;

is(
    $entries[-1]->date,
    DateTime->from_epoch(
        epoch     => $hello->stat->mtime,
        time_zone => 'America/New_York'
    ),
    'right mtime'
);
is( $entries[-1]->author,  'Chris Prather', 'right author' );
is( $entries[-1]->content, 'Hello World',   'right content' );
like( $entries[-1]->render_as_fragment, qr"<p>Hello World",
    'render correctly' );

is(
    $entries[0]->date,
    DateTime->from_epoch(
        epoch     => $bye->stat->mtime,
        time_zone => 'America/New_York'
    ),
    'right mtime'
);
is( $entries[0]->author,  'Chris Prather', 'right author' );
is( $entries[0]->content, 'Goodbye World', 'right content' );
like(
    $entries[0]->render_as_fragment,
    qr"<p>Goodbye World",
    'render correctly'
);

$blog = Blawd->new( repo => "$directory/.git", title => 'Test Blog' );
isa_ok( $blog->index, 'Blawd::Index' );
is( $blog->index->size, 2, 'index is the right size' );
like(
    $blog->get_index('index')->render,
    qr|<div class="entry"><p>Goodbye World|m,
    'index renders'
);

is_deeply( $entries[0], $blog->get_entry('goodbye'), 'entry compares okay' );

ok( my $rss = $blog->get_index('rss')->render, 'got RSS' );
is( $blog->get_index('rss')->render_as_fragment,
    $rss, 'fragment is the full RSS' );

ok($blog->get_index('rss')->render_to_file('/tmp/blawd_test_rss'), 'render to file');
is(file('/tmp/blawd_test_rss')->slurp, $rss, 'file output is good');

done_testing;
dir($directory)->rmtree;
file('/tmp/blawd_test_rss')->remove;