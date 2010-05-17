package Blawd::Cmd::Command::wp_export;
use Blawd::OO;
extends qw(Blawd::Cmd::Command::mt_export);
use Path::Class;

sub abstract {q[Import blog data from an existing Wordpress blog]}

sub _build_entry_query {
    q{
    SELECT *
    FROM wp_posts
    where post_status='publish';
    }
}

sub execute {
    my $self = shift;

    my $sth = $self->dbi->prepare( $self->entry_query );
    $sth->execute();

    my $i;
    while ( my $entry = $sth->fetchrow_hashref ) {
        chomp( my $name = lc $entry->{entry_title} );
        $name =~ s/["'<?!>#,*]|\.{3}$//g;
        $name =~ s{ ::? | \s | [/)(] }{-}gx;
        warn $name;
        $name = 'untitled' . ++$i unless $name;
        dir( $self->repo )->file($name)->openw->print( <<"END_ENTRY" );
Title: $entry->{post_title}
Author: ${\$self->author}
Date: $entry->{post_date}

## $entry->{entry_title}
$entry->{entry_content}
END_ENTRY

        $self->git->add($name);
    }
    $self->git->commit( { message => "import blog" } );

}

__PACKAGE__->meta->make_immutable;

1;
__END__
