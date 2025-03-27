package BlawdNexus::Index;
use v5.40;
use feature 'class';

class BlawdNexus::Index {
    field $title :param;
    field $filename :param;
    field $entries :param;
    field $config :param = {};
    
    method title { return $title }
    method filename { return $filename }
    method filename_base {
        my $name = $filename;
        $name =~ s/\.\w+$//;
        return $name;
    }
    
    method entries {
        return $entries;
    }
    
    method size {
        return scalar(@$entries);
    }
    
    method render($renderer) {
        return $renderer->render_index($self);
    }
    
    method render_fragment($renderer) {
        return $renderer->render_index_fragment($self);
    }
    
    method as_hash {
        return {
            title => $title,
            filename => $filename,
            entry_count => $self->size,
            config => $config,
        };
    }
}

package BlawdNexus::Index::Semantic;
use v5.40;
use feature 'class';

class BlawdNexus::Index::Semantic :isa(BlawdNexus::Index) {
    field $analyzer :param;
    
    method get_related_entries($entry, $count = 5) {
        return $analyzer->find_related($entry, $count);
    }
    
    method render($renderer) {
        if ($renderer->can('render_semantic_index')) {
            return $renderer->render_semantic_index($self);
        }
        return $renderer->render_index($self);
    }
}

package BlawdNexus::Index::Archive;
use v5.40;
use feature 'class';
use DateTime;

class BlawdNexus::Index::Archive :isa(BlawdNexus::Index) {
    field $grouping :param = 'monthly'; # monthly, yearly, or day
    field %grouped_entries;
    
    ADJUST {
        $self->build_archive();
    }
    
    method build_archive {
        for my $entry (@$entries) {
            my $date = $entry->date;
            next unless $date;
            
            my $key;
            if ($grouping eq 'yearly') {
                $key = $date->year;
            }
            elsif ($grouping eq 'daily') {
                $key = $date->ymd;
            }
            else { # monthly (default)
                $key = $date->year . '-' . sprintf('%02d', $date->month);
            }
            
            push @{$grouped_entries{$key}}, $entry;
        }
        
        # Sort entries within each group
        for my $key (keys %grouped_entries) {
            @{$grouped_entries{$key}} = sort { 
                $b->date <=> $a->date 
            } @{$grouped_entries{$key}};
        }
    }
    
    method get_archive_groups {
        my @keys = sort { $b cmp $a } keys %grouped_entries;
        my @groups;
        
        for my $key (@keys) {
            my $label;
            if ($grouping eq 'yearly') {
                $label = $key;
            }
            elsif ($grouping eq 'daily') {
                $label = DateTime->new(split('-', $key))->strftime('%B %d, %Y');
            }
            else { # monthly
                my ($year, $month) = split('-', $key);
                $label = DateTime->new(year => $year, month => $month, day => 1)
                    ->strftime('%B %Y');
            }
            
            push @groups, {
                key => $key,
                label => $label,
                entries => $grouped_entries{$key},
                count => scalar(@{$grouped_entries{$key}}),
            };
        }
        
        return @groups;
    }
    
    method render($renderer) {
        if ($renderer->can('render_archive_index')) {
            return $renderer->render_archive_index($self);
        }
        return $renderer->render_index($self);
    }
}

package BlawdNexus::Index::Tag;
use v5.40;
use feature 'class';

class BlawdNexus::Index::Tag :isa(BlawdNexus::Index) {
    field %tagged_entries;
    
    ADJUST {
        $self->build_tag_index();
    }
    
    method build_tag_index {
        for my $entry (@$entries) {
            for my $tag (@{$entry->tags}) {
                push @{$tagged_entries{$tag}}, $entry;
            }
        }
        
        # Sort entries within each tag
        for my $tag (keys %tagged_entries) {
            @{$tagged_entries{$tag}} = sort { 
                $b->date <=> $a->date 
            } @{$tagged_entries{$tag}};
        }
    }
    
    method get_tags {
        return sort keys %tagged_entries;
    }
    
    method get_entries_for_tag($tag) {
        return $tagged_entries{$tag} // [];
    }
    
    method get_tag_counts {
        my %counts;
        for my $tag (keys %tagged_entries) {
            $counts{$tag} = scalar(@{$tagged_entries{$tag}});
        }
        return %counts;
    }
    
    method render($renderer) {
        if ($renderer->can('render_tag_index')) {
            return $renderer->render_tag_index($self);
        }
        return $renderer->render_index($self);
    }
}

1;