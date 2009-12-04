package Blawd::Entry::MultiMarkdown;
use Blawd::OO;
use MooseX::Types::Path::Class qw(File);
use MooseX::Types::DateTimeX qw(DateTime);

sub _build_renderer { 'Blawd::Renderer::MultiMarkdown' }

has commit => ( is => 'ro', required => 1 );

sub _build_date {
    my $c = $_[0]->content;
    $c =~ m/^Date:\s+(.*)/m;
    return to_DateTime($1) if $1;
    return $_[0]->commit->committed_time;
}

sub _build_author {
    $_[0]->content =~ /^Author: (.*)\s*$/m;
    return $1 if $1;
    return $_[0]->commit->author->name;
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

with qw(Blawd::Entry::API);

__PACKAGE__->meta->make_immutable;
1;
__END__
