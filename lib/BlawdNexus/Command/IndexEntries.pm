package BlawdNexus::Command::IndexEntries;
use v5.40;
use experimental 'class';
use BlawdNexus::Builder;
use File::Temp qw(tempdir);
use Path::Tiny;
use Getopt::Long;
use DBI;

class BlawdNexus::Command::IndexEntries :isa(BlawdNexus::Command) {
    method description() {
        return "Update the semantic database";
    }
    
    method usage() {
        return "bn index-entries [--all] [--new]";
    }
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
        
        # Set defaults from config
        my $indexer_path = $opts{'indexer-path'} // 
                          $self->config->{semantic}{indexer_path} // 
                          "$ENV{HOME}/dev/commonplacebook/bin/indexer.pl";
                          
        my $db_path = $opts{'db-path'} // 
                     $self->config->{semantic}{db_path} // 
                     "$ENV{HOME}/dev/commonplacebook/.index.db";
        
        $self->info("Indexing entries for semantic relationships...");
        
        # Verify indexer exists
        unless (-x $indexer_path || -f $indexer_path) {
            $self->error("Error: Indexer script not found or not executable at '$indexer_path'");
            return 1;
        }
        
        # Load builder and get entries
        my $builder = BlawdNexus::Builder->new(
            # Use the accessor method to get config file path
            config_file => $self->config_file,
        );
        
        # Discover entries but don't build the full site
        $self->verbose_log("Discovering entries...");
        my @entries = $builder->discover_entries();
        
        $self->info("Found " . scalar(@entries) . " entries to process.");
        
        # Create a temporary directory for processing
        my $temp_dir = tempdir(CLEANUP => 1);
        $self->verbose_log("Using temporary directory: $temp_dir");
        
        # Process each entry
        my $indexed_count = 0;
        my $skipped_count = 0;
        my $error_count = 0;
        
        for my $entry (@entries) {
            my $filename = $entry->filename;
            my $basename = path($filename)->basename;
            
            # Check if entry should be indexed
            if ($opts{new} && !$opts{force} && $self->is_entry_indexed($entry, $db_path)) {
                $self->verbose_log("Skipping already indexed: $filename");
                $skipped_count++;
                next;
            }
            
            # Progress indicator
            $self->progress("Indexing ($indexed_count/" . scalar(@entries) . ")");
            $self->verbose_log("Indexing: $filename");
            
            # Write content to temporary file
            my $temp_file = path($temp_dir, $basename);
            $temp_file->spew_utf8($entry->content);
            
            # Call the external indexer
            my $cmd = "perl $indexer_path --mode=index --file=$temp_file";
            if ($opts{'db-path'} || $self->config->{semantic}{db_path}) {
                $cmd .= " --db-path=$db_path";
            }
            
            my $result = system($cmd);
            if ($result != 0) {
                $self->warn("Indexer returned error code " . ($result >> 8) . " for $filename");
                $error_count++;
            } else {
                $indexed_count++;
            }
        }
        
        # Clean up progress indicator
        $self->end_progress();
        
        # Show summary
        $self->success("Indexed $indexed_count entries.");
        $self->info("Skipped $skipped_count already indexed entries.") if $skipped_count;
        $self->warn("Encountered errors with $error_count entries.") if $error_count;
        $self->info("Semantic database updated at $db_path");
        
        return $error_count > 0 ? 1 : 0;
    }
    
    method is_entry_indexed($entry, $db_path) {
        # Don't check if database doesn't exist yet
        return 0 unless -f $db_path;
        
        # Connect to the database
        my $dbh = eval {
            DBI->connect(
                "dbi:SQLite:dbname=$db_path", 
                "", 
                "", 
                { RaiseError => 0, PrintError => 0 }
            );
        };
        
        return 0 unless $dbh; # Can't check, assume not indexed
        
        my $filename = $entry->filename;
        my $title = $entry->title;
        
        # Check if the entry exists in the documents table
        my $sth = eval {
            $dbh->prepare(
                "SELECT id FROM documents WHERE path LIKE ? OR title LIKE ?"
            );
        };
        
        return 0 unless $sth; # Can't check, assume not indexed
        
        $sth->execute("%$filename%", "%$title%");
        
        my $exists = $sth->fetchrow_arrayref ? 1 : 0;
        $dbh->disconnect;
        
        return $exists;
    }
}

1;
