package BlawdNexus::Semantic::Analyzer;
use v5.40;
use feature 'class';

class BlawdNexus::Semantic::Analyzer {
    field $entries :param;
    field $config :param = {};
    
    # Abstract methods that must be implemented by subclasses
    method analyze($entry) {
        die "Abstract method 'analyze' must be implemented by subclass";
    }
    
    method find_related($entry, $count = 5) {
        die "Abstract method 'find_related' must be implemented by subclass";
    }
    
    method build_index {
        die "Abstract method 'build_index' must be implemented by subclass";
    }
}

package BlawdNexus::Semantic::Adapter::Indexer;
use v5.40;
use feature 'class';
use DBI;
use List::Util qw(max);

class BlawdNexus::Semantic::Adapter::Indexer :isa(BlawdNexus::Semantic::Analyzer) {
    # Database connection parameters
    field $db_path :param = $ENV{HOME} . "/dev/commonplacebook/.index.db";
    field $db_handle;
    field $min_similarity :param = 0.3;
    field $max_related :param = 5;
    field %document_map;  # Maps filenames to database document IDs
    field %related_cache; # Cache for related entries

    ADJUST {
        $self->connect_db();
        $self->build_index();
    }
    
    method connect_db {
        $db_handle = DBI->connect(
            "dbi:SQLite:dbname=$db_path", 
            "", 
            "", 
            { RaiseError => 1, PrintError => 0 }
        ) or die "Cannot connect to database: $DBI::errstr";
    }
    
    method build_index {
        # Build a mapping between entry filenames and document IDs in the database
        for my $entry (@$entries) {
            my $filename = $entry->filename;
            my $title = $entry->title;
            
            # Query the database to find the corresponding document
            my $sth = $db_handle->prepare(
                "SELECT id FROM documents WHERE path LIKE ? OR title LIKE ?"
            );
            $sth->execute("%$filename%", "%$title%");
            
            if (my $row = $sth->fetchrow_hashref) {
                $document_map{$filename} = $row->{id};
            }
            else {
                # If not found, we could either:
                # 1. Add the document to the database (run indexer)
                # 2. Skip it for now and rely on external indexing
                warn "Document not found in semantic index: $filename\n";
            }
        }
    }
    
    method analyze($entry) {
        my $filename = $entry->filename;
        
        # Check if we have this document in our mapping
        my $doc_id = $document_map{$filename};
        return [] unless $doc_id;
        
        # Query the database for the top terms for this document
        my $sth = $db_handle->prepare(
            "SELECT term, weight FROM document_terms 
             WHERE document_id = ? 
             ORDER BY weight DESC LIMIT 10"
        );
        $sth->execute($doc_id);
        
        my @terms;
        while (my $row = $sth->fetchrow_hashref) {
            push @terms, $row->{term};
        }
        
        return \@terms;
    }
    
    method find_related($entry, $count = 5) {
        my $filename = $entry->filename;
        
        # Return from cache if available
        return $related_cache{$filename} if exists $related_cache{$filename};
        
        # Check if we have this document in our mapping
        my $doc_id = $document_map{$filename};
        return [] unless $doc_id;
        
        # Query the database for related documents
        my $sth = $db_handle->prepare(
            "SELECT d2.id, d2.path, d2.title, s.similarity 
             FROM similarities s
             JOIN documents d2 ON s.document2_id = d2.id
             WHERE s.document1_id = ? AND s.similarity >= ?
             ORDER BY s.similarity DESC
             LIMIT ?"
        );
        $sth->execute($doc_id, $min_similarity, $count);
        
        my @related;
        while (my $row = $sth->fetchrow_hashref) {
            # Find the entry object corresponding to this document
            my $related_entry;
            for my $e (@$entries) {
                if ($e->filename =~ /$row->{path}/ || $e->title =~ /$row->{title}/) {
                    $related_entry = $e;
                    last;
                }
            }
            
            # Only include if we found a matching entry
            if ($related_entry) {
                push @related, {
                    entry => $related_entry,
                    similarity => $row->{similarity}
                };
            }
        }
        
        # Cache the results
        $related_cache{$filename} = \@related;
        return \@related;
    }
    
    method get_document_id_for_entry($entry) {
        return $document_map{$entry->filename};
    }
    
    # Utility method to add a new entry to the semantic database
    # This could call your existing indexer script
    method index_new_entry($entry) {
        my $filename = $entry->filename;
        my $content = $entry->content;
        
        # Create a temporary file with the content
        my $temp_file = "/tmp/blawdnexus_temp_entry";
        open my $fh, '>', $temp_file or die "Cannot create temp file: $!";
        print $fh $content;
        close $fh;
        
        # Call your existing indexer
        system("perl $ENV{HOME}/dev/commonplacebook/bin/indexer.pl --mode=index --file=$temp_file");
        
        # Update our document map
        $self->build_index();
        
        # Clean up
        unlink $temp_file;
    }
}

1;