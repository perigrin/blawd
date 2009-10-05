package Blawd::Cmd::Command::mt_export;
use 5.10.0;
use Moose;
use namespace::autoclean;
extends qw(MooseX::App::Cmd::Command);
use DBI;
use Path::Class;
use Git::Wrapper;

has author => ( isa => 'Str', is => 'ro', );

has repo => (
    isa      => 'Str',
    is       => 'ro',
    coerce   => 1,
    required => 1
);

has blog_id => ( isa => 'Int', is => 'ro', default => 1 );

has [qw(db host port user pass)] =>
  ( isa => 'Str', is => 'ro', lazy_build => 1 );
sub _build_db   { '' }
sub _build_host { '127.0.01' }
sub _build_port { 3306 }
sub _build_user { $ENV{USER} }
sub _build_pass { '' }

sub dsn {
    my $s = shift;
    qq'DBI:mysql:${\$s->db};host=${\$s->host}';
}

has entry_query => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_entry_query {
    my ($self) = @_;

    q{
		SELECT *
		FROM mt_entry
		WHERE entry_blog_id = ?
		ORDER BY entry_authored_on ASC 
	}
}

has dbi => (
    is         => 'ro',
    traits     => ['NoGetopt'],
    lazy_build => 1,
);

sub _build_dbi {
    my ($self) = @_;
    DBI->connect( $self->dsn, $self->user, $self->pass );
}

has git => ( isa => 'Git::Wrapper', is => 'ro', lazy_build => 1, );

sub _build_git {
    my $self = shift;
    Git::Wrapper->new( $self->repo );
}

sub run {
    my $self = shift;

    my $sth = $self->dbi->prepare( $self->entry_query );
    $sth->execute( $self->blog_id );
    unless ( -d $self->repo ) {
        dir( $self->repo )->mkpath;
        $self->git->init;
    }
    my $i;
    while ( my $entry = $sth->fetchrow_hashref ) {
        chomp( my $name = lc $entry->{entry_title} );
        $name =~ s/["'<?!>#,*]|\.{3}$//g;
        $name =~ s{ ::? | \s | [/)(] }{-}gx;
        say $name;
        $name = 'untitled' . ++$i unless $name;
        dir( $self->repo )->file($name)->openw->print( <<"END_ENTRY" ); \
Title: $entry->{entry_title}  
Author: ${\$self->author}
Date: $entry->{entry_authored_on}

$entry->{entry_text}
END_ENTRY

          $self->git->add($name);
    }
    $self->git->commit( { message => "import blog" } );

}

__PACKAGE__->meta->make_immutable;
1;
__END__
