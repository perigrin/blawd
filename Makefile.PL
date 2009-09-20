use inc::Module::Install;
use 5.10.0;

all_from 'lib/Blawd.pm';

requires 'Moose' => 0.90;
requires 'MooseX::Types::Path::Class';
requires 'namespace::autoclean';
requires 'Memoize';
requires 'Template';

auto_manifest;
auto_repository;
WriteAll;
