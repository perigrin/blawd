use inc::Module::Install;
use 5.10.0;

all_from 'lib/Blawd.pm';

requires 'Moose' => 0.92;
requires 'MooseX::Types::Path::Class';
requires 'namespace::autoclean';
requires 'Memoize';
requires 'Template';
requires 'Try::Tiny';

build_requires 'Test::More' => 0.90;
build_requires 'Git::Wrapper';

auto_manifest;
auto_repository;
WriteAll;
