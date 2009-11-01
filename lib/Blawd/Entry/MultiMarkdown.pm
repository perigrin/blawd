package Blawd::Entry::MultiMarkdown;
use 5.10.0;
use Moose;
use MooseX::Types::Path::Class qw(File);
use MooseX::Types::DateTimeX qw(DateTime);
use namespace::autoclean;

sub _build_renderer { 'Blawd::Renderer::MultiMarkdown' }

sub _build_content { file( shift->filename )->slurp }

sub _build_date {
    my $c = shift->content;
    $c =~ m/^Date:\s+(.*)/m;
    return to_DateTime($1) if $1;
    return DateTime::->now;
}

sub _build_author {
    shift->content =~ /^Author: (.*)\s*$/m;
    return $1 if $1;
    return 'Unknown';
}

sub _build_title {
    $_[0]->content =~ /^Title: (.*)\s*$/m;
    return $1 if $1;
    return 'Unknown';
}

sub BUILDARGS {
    my ( $self ) = shift;
    my $p = $self->next::method(@_);
    given ( $p->{commit} ) {
        when ( !m/^Title:/m ) {
            $p->{title} //= '';
            continue;
        }
        when ( !m/^Author:/m ) {
            $p->{author} //= $p->{commit}->author->name;
            continue;
        }
        when ( !/^Date:/m ) {
            $p->{date} //= $p->{commit}->committed_time;
            continue;
        }
    }
    return $p;
}

with qw(Blawd::Entry::API);

__PACKAGE__->meta->make_immutable;
1;
__END__
