package Blawd::Index;
use Blawd::OO;

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

has render_factory => (
    isa      => 'Blawd::Renderer',
    handles  => ['get_renderer_for'],
    required => 1,
);

has content => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_content {
    my $s = shift;
    join '', (
        "# ${\$s->title}\n",
        map {
            my $r     = $s->get_renderer_for($_);
            my $title = $_->title;
            my $text  = $r->render_as_fragment($_);
            my $link  = $r->get_link_for($_);
            qq[\n\n<div class="entry">$text\n<a href="$link">link</a></div>]
          } $s->entries,
    );
}

sub _build_title { shift->filename }

sub BUILD {
    my ( $self, $p ) = @_;
    $self->meta->get_attribute('entries')
      ->set_value( $self, [ @{ $p->{entries} } ] );
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
