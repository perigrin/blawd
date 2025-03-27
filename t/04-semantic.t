#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use Path::Tiny;
use DBI;
use File::Temp qw(tempdir);
use BlawdNexus::Semantic::Analyzer;
use BlawdNexus::Semantic::Adapter::Indexer;
use BlawdNexus::Plugin;
use BlawdNexus::Plugin::RelatedContent;
use BlawdNexus::Plugin::SemanticMap;
use BlawdNexus::Plugin::SemanticRecommendations;

# Create a test database for semantic operations
sub setup_test_database {
    my $temp_dir = File::Temp::tempdir(CLEANUP => 1);
    my $db_path = "$temp_dir/test.db";
    
    # Create a test SQLite database
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", { RaiseError => 1 });
    
    # Create tables
    $dbh->do(q{
        CREATE TABLE documents (
            id INTEGER PRIMARY KEY,
            path TEXT,
            title TEXT
        )
    });
    
    $dbh->do(q{
        CREATE TABLE document_terms (
            document_id INTEGER,
            term TEXT,
            weight REAL,
            PRIMARY KEY (document_id, term)
        )
    });
    
    $dbh->do(q{
        CREATE TABLE similarities (
            document1_id INTEGER,
            document2_id INTEGER,
            similarity REAL,
            PRIMARY KEY (document1_id, document2_id)
        )
    });
    
    # Insert test data
    # Documents
    $dbh->do("INSERT INTO documents (id, path, title) VALUES (1, 'test1.md', 'Test Document 1')");
    $dbh->do("INSERT INTO documents (id, path, title) VALUES (2, 'test2.md', 'Test Document 2')");
    $dbh->do("INSERT INTO documents (id, path, title) VALUES (3, 'test3.md', 'Test Document 3')");
    $dbh->do("INSERT INTO documents (id, path, title) VALUES (4, 'test4.md', 'Test Document 4')");
    $dbh->do("INSERT INTO documents (id, path, title) VALUES (5, 'test5.md', 'Test Document 5')");
    
    # Document terms
    # Document 1 - Perl programming language
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (1, 'perl', 0.8)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (1, 'programming', 0.6)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (1, 'language', 0.5)");
    
    # Document 2 - Perl object and class system
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (2, 'perl', 0.8)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (2, 'object', 0.7)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (2, 'class', 0.7)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (2, 'system', 0.5)");
    
    # Document 3 - Zettlekasten knowledge management
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (3, 'zettlekasten', 0.9)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (3, 'knowledge', 0.7)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (3, 'management', 0.6)");
    
    # Document 4 - Knowledge management and Zettlekasten
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (4, 'knowledge', 0.8)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (4, 'management', 0.7)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (4, 'zettlekasten', 0.9)");
    
    # Document 5 - Programming languages like JavaScript
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (5, 'programming', 0.9)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (5, 'languages', 0.7)");
    $dbh->do("INSERT INTO document_terms (document_id, term, weight) VALUES (5, 'javascript', 0.8)");
    
    # Similarities
    # 1 and 2 - Perl documents
    $dbh->do("INSERT INTO similarities (document1_id, document2_id, similarity) VALUES (1, 2, 0.7)");
    $dbh->do("INSERT INTO similarities (document2_id, document1_id, similarity) VALUES (1, 2, 0.7)");
    
    # 3 and 4 - Zettlekasten documents
    $dbh->do("INSERT INTO similarities (document1_id, document2_id, similarity) VALUES (3, 4, 0.8)");
    $dbh->do("INSERT INTO similarities (document2_id, document1_id, similarity) VALUES (3, 4, 0.8)");
    
    # 1 and 5 - Programming documents
    $dbh->do("INSERT INTO similarities (document1_id, document2_id, similarity) VALUES (1, 5, 0.6)");
    $dbh->do("INSERT INTO similarities (document2_id, document1_id, similarity) VALUES (1, 5, 0.6)");
    
    # Weaker connections
    $dbh->do("INSERT INTO similarities (document1_id, document2_id, similarity) VALUES (1, 3, 0.3)");
    $dbh->do("INSERT INTO similarities (document2_id, document1_id, similarity) VALUES (1, 3, 0.3)");
    $dbh->do("INSERT INTO similarities (document1_id, document2_id, similarity) VALUES (2, 5, 0.4)");
    $dbh->do("INSERT INTO similarities (document2_id, document1_id, similarity) VALUES (2, 5, 0.4)");
    
    # Close the database connection
    $dbh->disconnect;
    
    return $db_path;
}

# Create mock entries for testing
package MockEntry {
    use v5.40;
    use experimental 'class';
    
    class MockEntry {
        field $title :param :reader;
        field $filename :param :reader;
        field $content :param :reader = '';
        field $tags :param :reader = [];
        field $similarity :reader;
        field $url :reader;
        
        method filename_base {
            my $name = $filename;
            $name =~ s/\.\w+$//;
            return $name;
        }
        
        method set_similarity($value) {
            $similarity = $value;
        }
        
        method set_url($value) {
            $url = $value;
        }
    }
}

# Set up the test database
my $test_db_path = setup_test_database();

# Create test entries that match our database
my @entries = (
    MockEntry->new(
        title => 'Test Document 1', 
        filename => 'test1.md',
        content => 'This is a test document about Perl programming language',
        tags => ['perl', 'programming']
    ),
    MockEntry->new(
        title => 'Test Document 2', 
        filename => 'test2.md',
        content => 'This is a test document about Perl object and class system',
        tags => ['perl', 'oop']
    ),
    MockEntry->new(
        title => 'Test Document 3', 
        filename => 'test3.md',
        content => 'This is a test document about Zettlekasten knowledge management',
        tags => ['zettlekasten', 'productivity']
    ),
    MockEntry->new(
        title => 'Test Document 4', 
        filename => 'test4.md',
        content => 'This is a test document about knowledge management and Zettlekasten',
        tags => ['knowledge', 'zettlekasten']
    ),
    MockEntry->new(
        title => 'Test Document 5', 
        filename => 'test5.md',
        content => 'This is a test document about programming languages like JavaScript',
        tags => ['programming', 'javascript']
    ),
);

# Create the analyzer with our test database
my $analyzer = BlawdNexus::Semantic::Adapter::Indexer->new(
    entries => \@entries,
    db_path => $test_db_path,
    verbose => 1,
);

# Test initialization
ok($analyzer, 'Created analyzer instance');
ok($analyzer->initialize, 'Initialized analyzer');

# Test document mapping
is($analyzer->get_document_id_for_entry($entries[0]), 1, 'Entry 1 maps to document ID 1');
is($analyzer->get_document_id_for_entry($entries[1]), 2, 'Entry 2 maps to document ID 2');

# Test entry lookup by document ID
is($analyzer->get_entry_for_document_id(1)->filename, 'test1.md', 'Document ID 1 maps to test1.md');
is($analyzer->get_entry_for_document_id(3)->filename, 'test3.md', 'Document ID 3 maps to test3.md');

# Test term analysis
my $terms = $analyzer->analyze($entries[0]);
is(scalar(@$terms), 3, 'Entry 1 has 3 terms');
like($terms, [qw(perl programming language)], 'Entry 1 terms are correct');

# Test related content finding
my $related = $analyzer->find_related($entries[0], 2);
is(scalar(@$related), 2, 'Found 2 related entries for Entry 1');

# Check the first related entry
my $first_related = $related->[0];
ok($first_related->{entry}, 'Related entry is present');
is($first_related->{entry}->title, 'Test Document 2', 'First related is Test Document 2');
is($first_related->{similarity}, 0.7, 'Similarity is 0.7');

# Test shared terms
my $shared = $analyzer->get_shared_terms($entries[0], $entries[1]);
like($shared, [qw(perl)], 'Shared term is perl');

# Test clusters
my $clusters = $analyzer->get_semantic_clusters(undef, 2, 0.3);
is(scalar(@$clusters), 2, 'Found 2 clusters with minimum size 2');

# Test that zettlekasten entries are clustered together
my $zettlekasten_cluster;
for my $cluster (@$clusters) {
    my $has_zettlekasten = grep { $_->title =~ /Document 3/ } @$cluster;
    if ($has_zettlekasten) {
        $zettlekasten_cluster = $cluster;
        last;
    }
}
ok($zettlekasten_cluster, 'Found cluster with zettlekasten entries');
is(scalar(@$zettlekasten_cluster), 2, 'Zettlekasten cluster has 2 entries');

# Test cluster themes
my $themes = $analyzer->get_cluster_themes([$entries[0], $entries[1], $entries[4]]);
ok(scalar(@$themes) > 0, 'Found themes for the cluster');
like($themes, array { item 'perl'; item 'programming'; etc; }, 'Cluster themes include perl and programming');

# Test term search
my $term_results = $analyzer->find_entry_by_term('programming');
is(scalar(@$term_results), 2, 'Found 2 entries with term "programming"');
is($term_results->[0]{entry}->title, 'Test Document 5', 'Highest weight for programming is in Document 5');

# Test semantic search
my $search_results = $analyzer->search('perl programming');
is(scalar(@$search_results), 3, 'Search returned 3 results');
is($search_results->[0]{entry}->title, 'Test Document 1', 'First search result is correct');

# Test connection discovery
my $connections = $analyzer->discover_connections($entries[2], 2, 0.3);
ok(%$connections, 'Found connections for entry');
ok(exists $connections->{'test4.md'}, 'Found connection to test4.md');

# Test that the connection path exists
my $test4_connection = $connections->{'test4.md'};
is($test4_connection->{similarity}, 0.8, 'Connection to test4 has similarity 0.8');
is(scalar(@{$test4_connection->{path}}), 0, 'Direct connection has no intermediary path');

# Test with a deeper connection (should find indirect paths)
my $deep_connections = $analyzer->discover_connections($entries[0], 2, 0.3);
ok(%$deep_connections, 'Found deep connections');
ok(exists $deep_connections->{'test4.md'}, 'Found connection to test4.md through intermediaries');

# Test cache clearing
ok($analyzer->clear_cache, 'Cache cleared');
$analyzer->initialize;  # Re-initialize after cache clear
ok($analyzer->get_document_id_for_entry($entries[0]), 'Still works after cache clear');

# Verify plugins are available
ok(BlawdNexus::Plugin->can('new'), 'Base Plugin class loaded');
ok(BlawdNexus::Plugin::RelatedContent->can('new'), 'RelatedContent plugin loaded');
ok(BlawdNexus::Plugin::SemanticMap->can('new'), 'SemanticMap plugin loaded');
ok(BlawdNexus::Plugin::SemanticRecommendations->can('new'), 'SemanticRecommendations plugin loaded');

# Create a RelatedContent plugin
my $plugin = BlawdNexus::Plugin::RelatedContent->new(
    name => 'TestRelatedContent',
    analyzer => $analyzer,
    count => 2,
    min_similarity => 0.5,
);

ok($plugin, 'Created RelatedContent plugin');
ok($plugin->enabled, 'Plugin is enabled by default');

# Test processing entry content
my $content = '<div>Test content</div>';
my $processed = $plugin->process($content, { entry => $entries[0] });
ok($processed ne $content, 'Content was modified');
like($processed, qr/<div class='related-content'>/, 'Contains related content wrapper');
like($processed, qr/Test Document 2/, 'Contains related entry title');

# Test SemanticRecommendations plugin
my $recommender = BlawdNexus::Plugin::SemanticRecommendations->new(
    name => 'TestRecommendations',
    analyzer => $analyzer,
    count => 2,
    show_reason => 1,
);

ok($recommender, 'Created SemanticRecommendations plugin');
my $rec_content = '<div>Test content</div>';
my $rec_processed = $recommender->process($rec_content, { entry => $entries[0] });
ok($rec_processed ne $rec_content, 'Content was modified by recommender');
like($rec_processed, qr/<div class='semantic-recommendations'>/, 'Contains recommendations wrapper');
like($rec_processed, qr/You Might Also Like/, 'Contains default title');

# Done
done_testing();