package Blawd::Index;
use Moose;
use DateTime;
use List::MoreUtils qw(uniq);
use namespace::autoclean;

with qw(Blawd::Renderable);

sub _build_renderer { 'Blawd::Renderer::MultiMarkdown' }

has entries => (
    isa      => 'ArrayRef',
    traits   => ['Array'],
    required => 1,
    handles  => {
        entries => 'elements',
        size    => 'count',
        next    => 'shift',
    },
);

has content => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_content {
    join '', map {
        my $title = $_->title;
        my $text  = $_->render_as_fragment;
        my $link  = $_->link;
        qq[\n\n<div class="entry">$text\n<a href="$link">link</a></div>]
    } shift->entries;
}

sub _build_title {
    shift->filename;
}

sub BUILD {
    my ( $self, $p ) = @_;

    my @entries = ( sort { $b->date cmp $a->date } @{ $p->{entries} } );
    @entries = @entries[ 0 .. 10 ] if @entries > 10;
    $self->meta->get_attribute('entries')->set_value( $self, \@entries );
}

with qw(Blawd::Page);

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Blawd::Index

=head1 SYNOPSIS

	Blawd::Index->new(
	    title    => $self->title,
	    filename => 'index',
	    headers  => $self->headers,
	    entries  => $self->entries
	),

=head1 DESCRIPTION

The Blawd::Index class implements indexes of Entries in a Blawd blog.

=head1 METHODS

=head2 BUILD ()

=head1 PRIVATE METHODS

=head2 _build_renderer

=head2 _build_author

=head2 _build_date

=head2 _build_content

=head2 _build_title

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
