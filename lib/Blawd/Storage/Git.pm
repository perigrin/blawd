package Blawd::Storage::Git;
use Moose;
use namespace::autoclean;
extends qw(Git::PurePerl);
with qw(Blawd::Storage::API);

use Try::Tiny;

sub find_entries {
    my ( $self, $commit ) = @_;
    $commit //= $self->master;
    my $tree = $commit->tree;

    my @output;
    for my $entry ( $tree->directory_entries ) {
        given ( $entry->object ) {
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

=head1 NAME

Blawd::Storage::Git - use Git as storage for Blawd blogs.

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

use Blawd::Storage::Git;

=head1 DESCRIPTION

The Blawd::Storage::Git class implements ...

=head1 METHODS

=head2 find_entries (Git::PurePerl::Object::Commit $commit)

Find all the entries in a given commit.

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
