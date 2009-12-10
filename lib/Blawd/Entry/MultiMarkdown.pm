package Blawd::Entry::MultiMarkdown;
use Blawd::OO;
use MooseX::Types::DateTimeX qw(DateTime);
use Text::MultiMarkdown ();

has markdown_instance => (
    isa        => 'Text::MultiMarkdown',
    is         => 'ro',
    lazy_build => 1,
    handles    => [qw(markdown)],
);

sub _build_markdown_instance {
    Text::MultiMarkdown->new(
        document_format => 1,
        use_metadata    => 1,
        strip_metadata  => 1,
    );
}

sub _build_date {
    my $c = $_[0]->content;
    $c =~ m/^Date:\s+(.*)/m;
    return to_DateTime($1) if $1;
    return $_[0]->storage_date;
}

sub _build_author {
    $_[0]->content =~ /^Author: (.*)\s*$/m;
    return $1 if $1;
    return $_[0]->storage_author;
}

sub _build_title {
    $_[0]->content =~ /^Title: (.*)\s*$/m;
    return $1 if $1;
    return '';
}

sub _build_tags {
    $_[0]->content =~ /^Tags: (.*)\s*$/m;
    return [ split ' ', $1 ] if $1;
    return [];
}

sub render_page_HTML {
    my $self = shift;
    my ($renderer) = @_;
    # XXX: should be able to hook into this to add comments, etc
    return $self->render_fragment_HTML($renderer);
}

sub render_fragment_HTML {
    my $self = shift;
    my ($renderer) = @_;
    my $content = $self->content . "\n";
    $content .= "By: ${\$self->author} on ${\$self->date}\n\n";
    $content .= "Tags: " . join ' ',
        map { "[$_](" . $renderer->base_uri . $_ . $renderer->extension . ')' }
        @{ $self->tags };
    $content .= "\n";
    return $self->markdown($content);
}

with qw(Blawd::Entry::API);

__PACKAGE__->meta->make_immutable;
1;
__END__
