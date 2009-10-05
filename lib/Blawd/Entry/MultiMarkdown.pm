package Blawd::Entry::MultiMarkdown;
use Moose;
use MooseX::Types::Path::Class qw(File);
use MooseX::Types::DateTimeX qw(DateTime);
use namespace::autoclean;
use Blawd::Renderer::MultiMarkdown;

has renderer => ( isa => 'Str', is => 'ro', lazy_build => 1 );
sub _build_renderer { 'Blawd::Renderer::MultiMarkdown' }

has filename => ( isa => 'Str', is => 'ro', required => 1, );

has file => ( isa => File, is => 'ro', lazy_build => 1 );
sub _build_file { file( shift->filename ) }

has content => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);
sub _build_content { shift->file->slurp }

has date => ( isa => DateTime, is => 'ro', coerce => 1, lazy_build => 1 );

sub _build_date {
    my $c = shift->content;
    $c =~ m/^Date:\s+(.*)/m;
    return to_DateTime($1);
}

has author => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_author {
    shift->content =~ /^Author: (.*)\s*$/;
    return $1 if $1;
    return 'Unknown';
}

sub BUILD {
    my ( $self, $p ) = @_;
    return unless $p->{commit};
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

1;
__END__
