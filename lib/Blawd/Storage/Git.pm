package Blawd::Storage::Git;
use Moose;
use namespace::autoclean;
extends qw(Git::PurePerl);
with qw(Blawd::Storage::API);

use Try::Tiny;
use Memoize;

sub check_tree {
    my ( $tree, $target ) = @_;
    my @subtree;
    {
        for my $entry ( $tree->directory_entries ) {
            given ( $entry->object ) {
                when ( $_->sha1 eq $target ) { return 1 }
                when ( $_->kind eq 'tree' ) { push @subtree, $_ }
            }
        }
    }
    return 1 if grep { check_tree( $_, $target ) } @subtree;
    return 0;
}

memoize 'check_tree';

sub find_commit {
    my ( $self, $commit, $target ) = @_;
    return $commit;

    return $commit unless $commit->parent;
    my $current = $commit;
    my %seen;
    while ( my $next = $current->parent ) {
        warn "seen" if $seen{ $next->sha1 }++;
        return $current unless check_tree( $next->tree, $target );
        $current = $next;
    }
    return $current;
}

sub find_entries {
    my ( $self, $commit, $tree ) = @_;
    $commit //= $self->master;
    $tree   //= $commit->tree;
    my @output;
    for my $entry ( $tree->directory_entries ) {
        given ( $entry->object ) {
            when ( $_->kind eq 'tree' ) {
                push @output, $self->find_entries( $commit, $entry->object );
            }
            when ( $_->kind eq 'blob' ) {
                push @output,
                  $self->new_entry(
                    content  => $_->content,
                    filename => $entry->filename,
                    commit   => $commit,
                  );
            }
        }
    }
    return @output;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
