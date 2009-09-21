package Blawd::Storage::Git;
use Moose;
use namespace::autoclean;
extends qw(Git::PurePerl);
with qw(Blawd::Storage::API);

use Blawd::Entry::Git;
use Memoize;

sub default_entry_class { 'Blawd::Entry::Git' }

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

    # return nothing if we don't have it
    return unless check_tree( $commit->tree, $target );

    # recurse into the tree and return the parent who has it
    if ( $commit->parent ) {
        my $parent = $self->find_commit( $commit->parent, $target );
        return $parent if defined $parent;
    }

    # default to returning ourselves if all else fails, we know we have it
    return $commit;
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
                    blob            => $_,
                    directory_entry => $entry,
                    commit => $self->find_commit( $commit, $entry->sha1 ),
                  );
            }
        }
    }
    @output = sort { $b->mtime cmp $a->mtime } @output;
    return @output;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
