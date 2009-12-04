package Blawd::OO;
use Moose::Exporter;
use 5.010;
use Moose 0.92 ();
use MooseX::Aliases ();
use namespace::autoclean ();

my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
    also => [qw(Moose MooseX::Aliases)],
);

sub import {
    my ($package) = @_;
    my $caller = caller;
    namespace::autoclean->import(
        -cleanee => $caller,
    );
    feature->import(':5.10');
    goto $import;
}

sub unimport {
    warn "'no " . __PACKAGE__ . "' is unnecessary";
    goto $unimport;
}

sub init_meta {
    my ($package, %opts) = @_;
    Moose->init_meta(%opts);
    goto $init_meta if $init_meta;
    return Class::MOP::class_of($opts{for_class});
}

1;
