#!/usr/bin/env perl
use 5.10.0;
use strict;
use warnings;
use Test::More;
use DateTime;
use Blawd;
use Git::PurePerl;
use Path::Class;

use aliased 'Git::PurePerl::NewObject::Blob';
use aliased 'Git::PurePerl::NewDirectoryEntry' => 'DirectoryEntry';
use aliased 'Git::PurePerl::NewObject::Tree';
use aliased 'Git::PurePerl::Actor';
use aliased 'Git::PurePerl::NewObject::Commit';

my $directory = 'blog-bare.git';

dir($directory)->rmtree;
my $blog = Blawd->new( repo => $directory, init => 1 );

# SET UP A POST

my $hello_mtime = DateTime->from_epoch( epoch => 1240341682 );

my $hello_blob = Blob->new( content => 'Hello World' );
is( $hello_blob->sha1, '5e1c309dae7f45e0f39b1bf3ac3cd9db12e7d689',
    'right sha1' );

$blog->storage->put_object($hello_blob);

my $hello = DirectoryEntry->new(
    mode     => '100644',
    filename => 'hello',
    sha1     => $hello_blob->sha1,
);

my $tree = Tree->new( directory_entries => [$hello] );

$blog->storage->put_object($tree);

my $commit = Commit->new(
    tree   => $tree->sha1,
    author => Actor->new(
        name  => 'Flexo',
        email => 'flexo@example.org',
    ),
    authored_time => DateTime->from_epoch( epoch => 1240341681 ),
    committer     => Actor->new(
        name  => 'Bender',
        email => 'bender@example.org',
    ),
    committed_time => $hello_mtime,
    comment        => 'Post',
);

$blog->storage->put_object($commit);

# TEST THE POST
ok( my @entries = $blog->find_entries, 'got entries' );
is( scalar @entries, 1, 'got only one post' );
ok( $_->does('Blawd::Entry::API'), 'does Blawd::Entry::API' ) for @entries;
is( $entries[0]->date,    $hello_mtime,  'right mtime' );
is( $entries[0]->author,  'Flexo',       'right author' );
is( $entries[0]->content, 'Hello World', 'right content' );
like( $entries[0]->render, qr'Hello World', 'render correctly' );

isa_ok( $blog->index, 'Blawd::Index' );
like( $blog->index->render, qr"Hello World", 'index renders' );

# SET UP A SECOND POST

my $bye_blob = Blob->new( content => 'Goodbye World' );
$blog->storage->put_object($bye_blob);

$tree = Tree->new(
    directory_entries => [
        DirectoryEntry->new(
            mode     => '100644',
            filename => 'goodbye',
            sha1     => $bye_blob->sha1,
        ),
        DirectoryEntry->new(
            mode     => '100644',
            filename => 'hello',
            sha1     => $hello_blob->sha1,
        ),
    ]
);

$blog->storage->put_object($tree);
my $bye_mtime = DateTime->from_epoch( epoch => 1240341782 );
$commit = Commit->new(
    tree   => $tree->sha1,
    author => Actor->new(
        name  => 'Fry',
        email => 'fry@example.org',
    ),
    authored_time => DateTime->from_epoch( epoch => 1240341782 ),
    committer     => Actor->new(
        name  => 'Bender',
        email => 'bender@example.org',
    ),
    committed_time => $bye_mtime,
    comment        => 'Post',
);
$blog->storage->put_object($commit);

ok( $blog->refresh, 'cleared the index' );
ok( @entries = $blog->find_entries, 'got entries' );
is( scalar @entries, 2, 'got two posts' );
ok( $_->does('Blawd::Entry::API'), 'does Blawd::Entry::API' ) for @entries;
TODO: {
    local $TODO =
      q[I think I'm doing the directory entry stuff in Git::PurePerl wrong];
    is( $entries[-1]->date,   $hello_mtime, 'right mtime' );
    is( $entries[-1]->author, 'Flexo',      'right author' );
}
is( $entries[-1]->content, 'Hello World', 'right content' );
like( $entries[-1]->render, qr'Hello World', 'render correctly' );

is( $entries[0]->date,    $bye_mtime,      'right mtime' );
is( $entries[0]->author,  'Fry',           'right author' );
is( $entries[0]->content, 'Goodbye World', 'right content' );
like( $entries[0]->render, qr'Goodbye World', 'render correctly' );

isa_ok( $blog->index, 'Blawd::Index' );
is( $blog->index->size, 2, 'index is the right size' );
like(
    $blog->index->render,
qr|<div class="entry"><p>Goodbye World</p>\s+</div><div class="entry"><p>Hello World</p>\s+</div>|m,
    'index renders'
);

done_testing;

dir($directory)->rmtree;
