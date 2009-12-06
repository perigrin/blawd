package Blawd::Storage::Git;
use Blawd::OO;
with qw(Blawd::Storage::API);

use Git::PurePerl;
use Scalar::Util qw(reftype);
use Try::Tiny;

has git => (
    is      => 'ro',
    isa     => 'Git::PurePerl',
    lazy    => 1,
    default => sub { Git::PurePerl->new(gitdir => shift->location) },
    handles => qr/.*/,
);

sub blawd_branch { return shift->master }

sub find_entries {
    my ($self) = @_;

    my $commit = $self->master;
    my $tree   = $commit->tree;

    my @output;
    for my $entry ( $tree->directory_entries ) {
        given ( $entry->object ) {
            when ( $_->kind eq 'blob' ) {
                push @output,
                  $self->new_entry(
                    content  => $_->content,
                    filename => $entry->filename,
                    commit   => $commit,
                  ) unless $entry->filename =~ /^\./;
            }
        }
    }
    return @output;
}

sub get_config {
    my $self = shift;
    my $tree = $self->master->tree;

    my ($config) = grep { $_->object->kind eq 'blob'
                       && $_->filename eq '.blawd' } $tree->directory_entries;
    return {} unless $config;
    return $self->parse_config($config);
}

sub is_valid_location {
    my $class = shift;
    my ($location) = shift;

    my $valid = 1;
    try {
        my $git = Git::PurePerl->new(gitdir => $location);
        $git->all_objects;
    }
    catch {
        $valid = 0;
    };

    return $valid;
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

=head2 blawd_branch

The Branch that this Blawd instance renders from.

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
