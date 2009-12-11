package Blawd::Entry::Text;
use Blawd::OO;

sub _build_date   { $_[0]->storage_date }
sub _build_author { $_[0]->storage_author }
sub _build_title  { '' }
sub _build_tags   { [] }

sub _build_body { $_[0]->content }

sub render_page_HTML {
    my $self = shift;
    my ($renderer) = @_;
    # XXX: should be able to hook into this to add comments, etc
    return '<div class="single_entry">' . "\n"
         . $self->render_fragment_HTML($renderer)
         . '</div>' . "\n";
}

sub render_fragment_HTML {
    my $self = shift;
    my ($renderer) = @_;
    my $content = $self->content;
    # XXX: use a real html escaper here or something
    $content =~ s/\&/\&amp;/g;
    $content =~ s/</\&lt;/g;
    return '<div class="entry">' . "\n"
         . '<pre>' . "\n"
         . $content . "\n"
         . "<p>By: ${\$self->author} on ${\$self->date}</p>\n"
         . "<p>Tags: " . join(' ', map {
             qq[<a href="${\$renderer->base_uri}${_}${\$renderer->extension}">$_</a>]
           } @{ $self->tags }) . '</p>' . "\n"
         . '</pre>' . "\n"
         . '</div>' . "\n";
}

sub is_valid_file {
    my $class = shift;
    my %options = @_;
    return 1 if $options{filename} =~ /\.txt$/;
    return 1 if $options{filename} !~ /\./;
    return 0;
}

with qw(Blawd::Entry::API);

__PACKAGE__->meta->make_immutable;
1;
__END__
