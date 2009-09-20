package Blawd::GitInterface;
use Moose;
use namespace::autoclean;
extends qw(Git::PurePerl);

use Blawd::Entry;
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
    my ( $self, $commit, $blob_sha1 ) = @_;
	if (check_tree($commit->tree, $blob_sha1)) {
    	return $self->find_commit( $commit->parent, $blob_sha1 ) // $commit;
	}
	return;
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
                  Blawd::Entry->new(
                    entry           => $_,
                    directory_entry => $entry,
                    commit => $self->find_commit( $commit, $entry->sha1 ),
                  );
            }
        }
    }
    return @output;
}

__PACKAGE__->meta->make_immutable;
1;
__END__
