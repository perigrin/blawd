package Blawd::Index;
use Blawd::OO;

has entries => (
    isa      => 'ArrayRef[Blawd::Entry::API]',
    traits   => ['Array'],
    required => 1,
    handles  => {
        entries => 'elements',
        size    => 'count',
    },
);

sub _build_title { shift->filename_base }

sub render_page_default {
    my $self = shift;
    my ($renderer) = @_;
    return $self->render_fragment($renderer);
}

sub render_fragment_default {
    my $self = shift;
    my ($renderer) = @_;
    return join "\n\n", map { $_->render_fragment($renderer) } $self->entries;
}

sub render_page_HTML {
    my $self = shift;
    my ($renderer) = @_;
    return $self->render_fragment_HTML($renderer);
}

sub render_fragment_HTML {
    my $self = shift;
    my ($renderer) = @_;
    return '<div class="index">' . "\n"
         . (join "\n", map { $_->render_fragment($renderer) } $self->entries)
         . '</div>' . "\n";
}

with qw(Blawd::Renderable);

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
