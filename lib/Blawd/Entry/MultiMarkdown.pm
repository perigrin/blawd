package Blawd::Entry::MultiMarkdown;
use Blawd::OO;
use MooseX::Types::DateTime::MoreCoercions qw(DateTime);
use Text::MultiMarkdown ();
use URI::Escape;

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
    my $self = shift;
    my $content = $self->content;

    return [] unless $content =~ /^Tags: (.*)\s*$/m;
    my $tags = $1;

    if ($tags =~ /,/) {
        # Comma-based tags
        return [ split /\s*,\s*+/, $tags ];
    } else {
        return [ split ' ', $tags ];
    }
}

sub _build_body {
    my $self = shift;
    my $content = $self->content;
    if ((split(/\n/, $content))[0] =~ /^\w+:/) {
        $content =~ s/^.*?\n\n//s;
    }
    return $content;
}

sub _build_permalink {
    my ($self, $renderer) = @_;
    my $link = uri_escape($_[0]->filename_base);
    qq[<a href="${\$renderer->base_uri}${link}${\$renderer->extension}">permalink</a>];
}

sub render_page_HTML {
    my $self = shift;
    my ($renderer) = @_;
    # XXX: should be able to hook into this to add comments, etc
    return '<article><div class="single_entry">' . "\n"
         . $self->render_fragment_HTML($renderer)
         . '</div></article>' . "\n";
}

sub render_fragment_HTML {
    my $self = shift;
    my ($renderer) = @_;
    my $content = $self->content . "\n";
    $content .= "By: ${\$self->author} on ${\$self->date}\n\n";
    $content .= "Tags: " . join ' ',
        map { "[$_](" . $renderer->base_uri . $_ . $renderer->extension . ')' }
        @{ $self->tags };
    $content .= "\n\n";
    $content .= $self->_build_permalink($renderer);
    $content .= "\n";
    return '<article><div class="entry">' . $self->markdown($content) . '</div></article>';
}

sub is_valid_file {
    my $class = shift;
    my (%options) = @_;
    return 1 if $options{filename} =~ /\.md(?:wn)?$/;
    return 0;
}

with qw(Blawd::Entry::API);

__PACKAGE__->meta->make_immutable;
1;
__END__
