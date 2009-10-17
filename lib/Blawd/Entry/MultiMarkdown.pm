package Blawd::Entry::MultiMarkdown;
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
    return 'Unknown';
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

sub BUILD {
    my ( $self, $p ) = @_;
    return unless $p->{commit};
    unless ( $self->content =~ /^Title:/m ) {
        $self->meta->get_attribute('title')
          ->set_value( $self, $p->{commit}->filename );
    }

    unless ( $self->content =~ /^Author:/m ) {
        $self->meta->get_attribute('author')
          ->set_value( $self, $p->{commit}->author->name );
    }

    unless ( $self->content =~ /^Date:/m ) {
        $self->meta->get_attribute('date')
          ->set_value( $self, $p->{commit}->committed_time );
    }

}

with qw(Blawd::Entry::API);

__PACKAGE__->meta->make_immutable;
1;
__END__
