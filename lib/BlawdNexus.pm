package BlawdNexus;
use v5.40;

our $VERSION = '0.001';

1;

__END__

=head1 NAME

BlawdNexus - A modern static site generator with semantic indexing

=head1 SYNOPSIS

  # Command-line usage
  $ bn build
  $ bn serve --port 8080 --watch
  $ bn new --title "My New Post" --tags "perl,programming"

  # API usage
  use BlawdNexus::Builder;
  
  my $builder = BlawdNexus::Builder->new(
      config_file => './bn.yml',
  );
  
  my $nexus = $builder->build();
  $nexus->render_all('./output');

=head1 DESCRIPTION

BlawdNexus is a modern static site generator that builds upon the original Blawd project
but updated with Perl 5.40's class feature syntax and enhanced with semantic indexing 
capabilities to provide sophisticated "related content" suggestions.

=head1 FEATURES

=over 4

=item * Modern Perl 5.40 features

=item * Semantic connections using your existing Commonplace Book database

=item * Clean, template-based rendering

=item * Multiple output formats (HTML, RSS, Atom, JSON)

=item * Simple CLI interface

=back

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
