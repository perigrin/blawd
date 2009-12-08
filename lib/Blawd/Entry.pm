package Blawd::Entry;
use Blawd::Entry::MultiMarkdown;

# Eventually this will have a lookup system similar to Blawd::Storage
# right now we only need to hardcode MultiMarkdown

sub new_entry {
    my $class = shift;
    Blawd::Entry::MultiMarkdown->new(@_);
}

1;
__END__
