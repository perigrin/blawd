package Blawd::Entry;
use Module::Pluggable (
    require     => 1,
    sub_name    => 'entry_classes',
    search_path => [__PACKAGE__],
    except      => qr/Meta|Role|API/,
);

sub determine_entry_class {
    my $class = shift;

    for my $entry_class ($class->entry_classes) {
        return $entry_class if $entry_class->is_valid_file(@_);
    }
    return;
}

sub create_entry {
    my $class = shift;
    my %options = @_;

    my $entry_class = $class->determine_entry_class(%options);
    die "Could not determine the proper entry class for " . $options{filename}
      . " (tried " . join(', ', $class->entry_classes) . ")"
        unless defined($entry_class);
    return $entry_class->new(%options);
}

1;
__END__
