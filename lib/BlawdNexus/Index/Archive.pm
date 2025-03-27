package BlawdNexus::Index::Archive;
use v5.40;
use experimental 'class';
use Time::Piece;
use Time::Local;

class BlawdNexus::Index::Archive :isa(BlawdNexus::Index) {
    field $grouping :param = 'monthly'; # monthly, yearly, or daily
    field %grouped_entries;
    
    ADJUST {
        $self->build_archive();
    }
    
    method build_archive {
        my $entries = $self->entries;
        for my $entry (@$entries) {
            my $date = $entry->date;
            next unless $date;
            
            my $key;
            if ($grouping eq 'yearly') {
                $key = $date->year;
            }
            elsif ($grouping eq 'daily') {
                $key = $date->strftime('%Y-%m-%d');
            }
            else { # monthly (default)
                $key = $date->year . '-' . $date->strftime('%m');
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
                my ($year, $month, $day) = split('-', $key);
                my $date = Time::Piece->new(Time::Local::timelocal(0, 0, 0, $day, $month-1, $year-1900));
                $label = $date->strftime('%B %d, %Y');
            }
            else { # monthly
                my ($year, $month) = split('-', $key);
                my $date = Time::Piece->new(Time::Local::timelocal(0, 0, 0, 1, $month-1, $year-1900));
                $label = $date->strftime('%B %Y');
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

1;
