#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use Time::Piece;
use Time::Local;

# Test the base Index class
use BlawdNexus::Index;

# Create a mock entry class for testing
package MockEntry {
    use v5.40;
    use experimental 'class';
    
    class MockEntry {
        field $title :param;
        field $filename :param;
        field $date :param;
        field $tags :param = [];
        
        method title { return $title }
        method filename { return $filename }
        method filename_base {
            my $name = $filename;
            $name =~ s/\.\w+$//;
            return $name;
        }
        method date { return $date }
        method tags { return $tags }
    }
};

# Create test entries
my @entries = (
    MockEntry->new(
        title => 'Test Entry 1',
        filename => 'test-entry-1.md',
        date => Time::Piece->new(Time::Local::timelocal(0, 0, 0, 15, 0, 123)),  # 2023-01-15
        tags => ['perl', 'test'],
    ),
    MockEntry->new(
        title => 'Test Entry 2',
        filename => 'test-entry-2.md',
        date => Time::Piece->new(Time::Local::timelocal(0, 0, 0, 20, 1, 123)),  # 2023-02-20
        tags => ['perl', 'programming'],
    ),
    MockEntry->new(
        title => 'Test Entry 3',
        filename => 'test-entry-3.md',
        date => Time::Piece->new(Time::Local::timelocal(0, 0, 0, 25, 2, 123)),  # 2023-03-25
        tags => ['test', 'example'],
    ),
);

# Test base index
my $base_index = BlawdNexus::Index->new(
    title => 'Test Index',
    filename => 'test-index.html',
    entries => \@entries,
);

is($base_index->title, 'Test Index', 'Base index title');
is($base_index->filename, 'test-index.html', 'Base index filename');
is($base_index->filename_base, 'test-index', 'Base index filename_base');
is($base_index->size, 3, 'Base index has correct number of entries');

# Test archive index
use BlawdNexus::Index::Archive;

my $archive_index = BlawdNexus::Index::Archive->new(
    title => 'Archive',
    filename => 'archive.html',
    entries => \@entries,
    grouping => 'monthly',
);

my @groups = $archive_index->get_archive_groups();
is(scalar(@groups), 3, 'Archive has correct number of groups');
is($groups[0]->{count}, 1, 'First group has correct number of entries');
is($groups[0]->{label}, 'March 2023', 'First group has correct label');

# Test tag index
use BlawdNexus::Index::Tag;

my $tag_index = BlawdNexus::Index::Tag->new(
    title => 'Tags',
    filename => 'tags.html',
    entries => \@entries,
);

my @tags = $tag_index->get_tags();
is(scalar(@tags), 4, 'Tag index has correct number of tags');
like(\@tags, bag {
    item 'perl';
    item 'test';
    item 'programming';
    item 'example';
    end;
}, 'Tags contain all expected items regardless of order');

my %counts = $tag_index->get_tag_counts();
is($counts{perl}, 2, 'perl tag has correct count');
is($counts{test}, 2, 'test tag has correct count');

my $perl_entries = $tag_index->get_entries_for_tag('perl');
is(scalar(@$perl_entries), 2, 'Correct number of entries for perl tag');

# Test semantic index - using a mock analyzer
use BlawdNexus::Index::Semantic;

# Create a mock analyzer
package MockAnalyzer {
    use v5.40;
    use experimental 'class';
    
    class MockAnalyzer {
        method find_related($entry, $count) {
            return [
                {
                    entry => MockEntry->new(
                        title => 'Related Entry',
                        filename => 'related.md',
                        date => Time::Piece->new,
                    ),
                    similarity => 0.8,
                }
            ];
        }
    }
};

my $semantic_index = BlawdNexus::Index::Semantic->new(
    title => 'Related',
    filename => 'related.html',
    entries => \@entries,
    analyzer => MockAnalyzer->new(),
);

my $related = $semantic_index->get_related_entries($entries[0]);
is(scalar(@$related), 1, 'Semantic index returns related entries');
is($related->[0]->{similarity}, 0.8, 'Similarity score is correct');

done_testing();
