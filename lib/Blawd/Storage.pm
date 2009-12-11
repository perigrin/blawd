package Blawd::Storage;
use Module::Pluggable (
    require     => 1,
    sub_name    => 'storage_classes',
    search_path => [__PACKAGE__],
    except      => qr/Meta|Role|API/,
);

sub determine_storage_class {
    my $class = shift;

    for my $storage_class ($class->storage_classes) {
        return $storage_class if $storage_class->is_valid_location(@_);
    }
    return;
}

sub create_storage {
    my $class = shift;
    my ($location) = @_;

    my $storage_class = $class->determine_storage_class($location);
    die "Could not determine the proper storage class for " . $location
      . " (tried " . join(', ', $class->storage_classes) . ")"
        unless defined($storage_class);
    return $storage_class->new(location => $location);
}

1;
