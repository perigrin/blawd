package Blawd::Archive;
use Blawd::OO;
extends 'Blawd::Index';

sub render_page_HTML {
    my $self = shift;
    return '<div class="index"><h1>Archives</h1><ul>' . (
        join "\n",
        map {
            "<li>"
              . $_->title
              . ' &#8212; <span class="timestamp">'
              . $_->date
              . "</span></li>"
          } $self->entries
    ) . "</ul></div>";
}



sub render_fragment_HTML {
    my $self = shift;
    $self->render_page_HTML();
}

with qw/Blawd::Renderable/;

__PACKAGE__->meta->make_immutable;

1;
__END__
