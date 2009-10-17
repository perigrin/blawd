#!/usr/bin/perl 
use strict;
use Test::More;
use Try::Tiny;
use Path::Class;
use Blawd;

BEGIN {
    try { use Git::Wrapper }
    catch { plan skip_all => 'Tests Require Git::Wrapper ' };
}

my $directory = 'my-blog';
dir($directory)->rmtree if -e $directory;
dir($directory)->mkpath;

my $g = Git::Wrapper->new($directory);
$g->init;
my $hello = dir($directory)->file('hello');
$hello->openw->print('Hello World');
$g->add('hello');
$g->commit( { message => 'first post' } );

ok( my $blog = Blawd->new( repo => "$directory/.git" ), 'new blawd' );

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
is( $entries[0]->author,  'Chris Prather',        'right author' );
is( $entries[0]->content, 'Hello World',          'right content' );
is( $entries[0]->render_as_fragment,  "<p>Hello World</p>\n", 'render correctly' );

isa_ok( $blog->index, 'Blawd::Index' );
like( $blog->index->render, qr"<p>Hello World</p>\n", 'index renders' );

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
is( $entries[-1]->author,  'Chris Prather',        'right author' );
is( $entries[-1]->content, 'Hello World',          'right content' );
is( $entries[-1]->render_as_fragment,  "<p>Hello World</p>\n", 'render correctly' );

is(
    $entries[0]->date,
    DateTime->from_epoch(
        epoch     => $bye->stat->mtime,
        time_zone => 'America/New_York'
    ),
    'right mtime'
);
is( $entries[0]->author,  'Chris Prather',          'right author' );
is( $entries[0]->content, 'Goodbye World',          'right content' );
is( $entries[0]->render_as_fragment,  "<p>Goodbye World</p>\n", 'render correctly' );

$blog = Blawd->new( repo => "$directory/.git" );
isa_ok( $blog->index, 'Blawd::Index' );
is( $blog->index->size, 2, 'index is the right size' );
like(
    $blog->index->render,
    qr|<div class="entry"><p>Goodbye World</p>\s+</div><div class="entry"><p>Hello World</p>\s+</div>|m,
    'index renders'
);

done_testing;
dir($directory)->rmtree;
