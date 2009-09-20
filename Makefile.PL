use inc::Module::Install;
use 5.10.0;

all_from 'lib/Blawd.pm';

requires 'Memoize';
requires 'Moose';
requires 'MooseX::Types::Path::Class';
requires 'Template';
requires 'namespace::autoclean';

auto_manifest;
auto_repository;
WriteAll;
