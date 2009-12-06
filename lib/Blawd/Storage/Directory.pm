package Blawd::Storage::Directory;
use Blawd::OO;
with qw(Blawd::Storage::API);

use File::Spec;

sub _slurp {
    my $self = shift;
    my ($file) = @_;
    open my $fh, '<', $file;
    local $/;
    return scalar <$fh>;
}

sub find_entries {
    my $self = shift;
    my $dir = $self->location;

    my @output;
    # glob('*') doesn't include dotfiles
    for my $file (glob(File::Spec->catfile($dir, '*'))) {
        next unless -r $file;
        my @stat = stat($file);
        my ($uid, $mtime) = ($stat[4], $stat[9]);
        my @userdata = getpwuid($uid);
        my ($user, $gcos) = ($userdata[0], $userdata[6]);
        $gcos =~ s/,.*//;

        push @output, $self->new_entry(
            content        => $self->_slurp($file),
            filename       => File::Spec->abs2rel($file, $dir),
            storage_author => $gcos // $user,
            storage_date   => $mtime,
        );
    }

    return @output;
}

sub get_config {
    my $self = shift;
    my $config_file = File::Spec->catfile($self->location, '.blawd');
    if (-r $config_file) {
        my $cfg_data = $self->_slurp($config_file);
        return $self->parse_config($cfg_data);
    }
    else {
        return {};
    }
}

sub is_valid_location {
    my $class = shift;
    my ($location) = @_;
    return -d $location && -r File::Spec->catfile($location, '.blawd');
}

__PACKAGE__->meta->make_immutable;

1;
