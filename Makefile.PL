use inc::Module::Install;
use 5.10.0;

all_from 'lib/Blawd.pm';

requires 'aliased';
requires 'DateTime';
requires 'DBI';
requires 'Git::PurePerl';
requires 'HTTP::Engine';
requires 'Memoize';
requires 'Memoize';
requires 'Moose' => '0.92';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::DateTimeX';
requires 'MooseX::Types::Path::Class';
requires 'namespace::autoclean';
requires 'Path::Class';
requires 'Template';
requires 'Text::MultiMarkdown' => '1.0.30';
requires 'Try::Tiny';
requires 'XML::RSS';

build_requires 'Test::More' => 0.90;
build_requires 'Git::Wrapper';

auto_manifest;
auto_repository;
WriteAll;
