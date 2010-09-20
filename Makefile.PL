use inc::Module::Install;
use 5.10.0;

all_from 'lib/Blawd.pm';

requires 'aliased';
requires 'Bread::Board';
requires 'DateTime';
requires 'DBI';
requires 'Git::PurePerl';
requires 'Plack' => '0.99_01';
requires 'Memoize';
requires 'Module::Pluggable';
requires 'Moose' => '0.92';
requires 'MooseX::Aliases';
requires 'MooseX::App::Cmd';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::DateTimeX';
requires 'MooseX::Types::Path::Class';
requires 'namespace::autoclean';
requires 'Path::Class';
requires 'Text::MultiMarkdown' => '1.0.30';
requires 'Try::Tiny';
requires 'XML::RSS';
requires 'XML::Atom::Feed';
requires 'YAML';

build_requires 'Test::More' => 0.90;
build_requires 'Git::Wrapper';

auto_manifest;
WriteAll;
