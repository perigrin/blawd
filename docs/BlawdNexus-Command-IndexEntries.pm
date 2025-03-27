package BlawdNexus::Command::IndexEntries;
use v5.40;
use feature 'class';
use BlawdNexus::Builder;
use File::Temp qw(tempdir);
use Path::Tiny;

class BlawdNexus::Command::IndexEntries :isa(BlawdNexus::Command) {
    method execute(@args) {
        # Parse indexing-specific options
        my %opts;
        GetOptions(
            \%opts,
            'all',                    # Index all entries
            'new',                    # Only index new entries 
            'indexer-path=s',         # Path to your existing indexer script
            'db-path=s',              # Path to your semantic database
            'force|f',                # Force reindexing
        );
        
        # Set defaults
        my $indexer_path = $opts{'indexer-path'} // "$ENV{HOME}/dev/commonplacebook/bin/indexer.pl";
        my $db_path = $opts{'db-path'} // "$ENV{HOME}/dev/commonplacebook/.index.db";
        
        print "Indexing entries for semantic relationships...\n";
        
        # Load builder and get entries
        my $builder = BlawdNexus::Builder->new(
            config_file => $config_file,
        );
        
        # Discover entries but don't build the full site
        my @entries = $builder->discover_entries();
        
        print "Found " . scalar(@entries) . " entries to process.\n";
        
        # Create a temporary directory for processing
        my $temp_dir = tempdir(CLEANUP => 1);
        
        # Process each entry
        my $indexed_count = 0;
        for my $entry (@entries) {
            my $filename = $entry->filename;
            my $basename = path($filename)->basename;
            
            # Check if entry should be indexed based on options
            next if $opts{new} && $self->is_entry_indexed($entry, $db_path);
            
            print "Indexing: $filename\n" if $verbose;
            
            # Write content to temporary file
            my $temp_file = path($temp_dir, $basename);
            $temp_file->spew_utf8($entry->content);
            
            # Call the external indexer
            my $cmd = "perl $indexer_path --mode=index --file=$temp_file";
            if ($opts{'db-path'}) {
                $cmd .= " --db-path=$db_path";
            }
            
            system($cmd);
            
            $indexed_count++;
        }
        
        print "Indexed $indexed_count entries.\n";
        print "Semantic database updated at $db_path\n";
        
        return 0;
    }
    
    method is_entry_indexed($entry, $db_path) {
        # Connect to the database
        my $dbh = DBI->connect(
            "dbi:SQLite:dbname=$db_path", 
            "", 
            "", 
            { RaiseError => 0, PrintError => 0 }
        );
        
        return 0 unless $dbh; # Can't check, assume not indexed
        
        my $filename = $entry->filename;
        my $title = $entry->title;
        
        # Check if the entry exists in the documents table
        my $sth = $dbh->prepare(
            "SELECT id FROM documents WHERE path LIKE ? OR title LIKE ?"
        );
        $sth->execute("%$filename%", "%$title%");
        
        my $exists = $sth->fetchrow_arrayref ? 1 : 0;
        $dbh->disconnect;
        
        return $exists;
    }
}

1;