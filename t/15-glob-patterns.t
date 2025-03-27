#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use Path::Tiny;
use BlawdNexus::Util qw(glob_to_regex match_pattern);

# Test glob pattern matching functionality

# Test basic glob patterns
subtest 'basic_glob_patterns' => sub {
    my $pattern = '*.md';
    my $regex = glob_to_regex($pattern);
    
    ok('test.md' =~ $regex, '*.md matches test.md');
    ok('README.md' =~ $regex, '*.md matches README.md');
    ok(!('test.txt' =~ $regex), '*.md does not match test.txt');
    ok(!('test.mdx' =~ $regex), '*.md does not match test.mdx');
};

# Test complex glob patterns
subtest 'complex_glob_patterns' => sub {
    my $pattern = '?est.md';
    my $regex = glob_to_regex($pattern);
    
    ok('test.md' =~ $regex, '?est.md matches test.md');
    ok('best.md' =~ $regex, '?est.md matches best.md');
    ok(!('ttest.md' =~ $regex), '?est.md does not match ttest.md');
    
    # Character class pattern
    $pattern = '[abc].md';
    $regex = glob_to_regex($pattern);
    
    ok('a.md' =~ $regex, '[abc].md matches a.md');
    ok('b.md' =~ $regex, '[abc].md matches b.md');
    ok('c.md' =~ $regex, '[abc].md matches c.md');
    ok(!('d.md' =~ $regex), '[abc].md does not match d.md');
    ok(!('abc.md' =~ $regex), '[abc].md does not match abc.md');
};

# Test match_pattern function
subtest 'match_pattern_function' => sub {
    # Simple patterns
    ok(match_pattern('test.md', '*.md'), '*.md matches test.md');
    ok(!match_pattern('test.txt', '*.md'), '*.md does not match test.txt');
    
    # Path objects
    my $file = path('test.md');
    ok(match_pattern($file, '*.md'), '*.md matches Path::Tiny objects');
    
    # Full paths
    ok(match_pattern('/path/to/test.md', '*.md'), '*.md matches files in paths');
    
    # Case insensitivity
    ok(match_pattern('README.MD', '*.md'), '*.md matches README.MD (case insensitive)');
    ok(match_pattern('readme.md', '*.MD'), '*.MD matches readme.md (case insensitive)');
};

# Test matching in directory with Path::Tiny
subtest 'path_tiny_matching' => sub {
    my $dir = Path::Tiny->tempdir;
    
    # Create some test files
    $dir->child('readme.md')->touch;
    $dir->child('test.md')->touch;
    $dir->child('notes.txt')->touch;
    $dir->child('image.png')->touch;
    
    # Test glob matching with our function
    my @md_files = sort map { $_->basename } 
                   grep { match_pattern($_, '*.md') } 
                   $dir->children;
    is(\@md_files, ['readme.md', 'test.md'], '*.md matches all markdown files');
    
    my @txt_files = sort map { $_->basename }
                    grep { match_pattern($_, '*.txt') }
                    $dir->children;
    is(\@txt_files, ['notes.txt'], '*.txt matches all text files');
};

done_testing();