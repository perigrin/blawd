package BlawdNexus::CLI;
use v5.40;
use feature 'class';
use Getopt::Long;
use Pod::Usage;

class BlawdNexus::CLI {
    method run(@args) {
        my %opts;
        GetOptions(
            \%opts,
            'help|h',
            'config|c=s',
            'verbose|v',
        );
        
        pod2usage(1) if $opts{help} || !@args;
        
        my $command = shift @args;
        my $command_class = "BlawdNexus::Command::" . ucfirst($command);
        
        eval "require $command_class";
        if ($@) {
            die "Unknown command: $command\n";
        }
        
        my $cmd = $command_class->new(
            config_file => $opts{config} // './bn.yml',
            verbose => $opts{verbose},
        );
        
        $cmd->execute(@args);
    }
}

package BlawdNexus::Command;
use v5.40;
use feature 'class';

class BlawdNexus::Command {
    field $config_file :param = './bn.yml';
    field $verbose :param = 0;
    
    method execute(@args) {
        die "Abstract method 'execute' must be implemented by subclass";
    }
    
    method verbose_log($message) {
        print "$message\n" if $verbose;
    }
}

package BlawdNexus::Command::Build;
use v5.40;
use feature 'class';
use BlawdNexus::Builder;

class BlawdNexus::Command::Build :isa(BlawdNexus::Command) {
    method execute(@args) {
        print "Building site...\n";
        
        my $builder = BlawdNexus::Builder->new(
            config_file => $config_file,
        );
        
        $self->verbose_log("Loading configuration from $config_file");
        my $nexus = $builder->build();
        
        $self->verbose_log("Discovered " . scalar(@{$nexus->entries}) . " entries");
        $self->verbose_log("Created " . scalar(@{$nexus->indexes}) . " indexes");
        
        my $output_dir = $nexus->config->{output}{path} // './public';
        $self->verbose_log("Rendering to $output_dir");
        
        $nexus->render_all($output_dir);
        
        print "Site built successfully in $output_dir\n";
        return 0;
    }
}

package BlawdNexus::Command::Serve;
use v5.40;
use feature 'class';
use Plack::Builder;
use Plack::Runner;
use Plack::App::Directory;
use File::Watcher::Simple;

class BlawdNexus::Command::Serve :isa(BlawdNexus::Command) {
    method execute(@args) {
        # Parse serve-specific options
        my %opts;
        GetOptions(
            \%opts,
            'port|p=i',
            'host|h=s',
            'watch|w',
        );
        
        # Load builder and build site
        my $builder = BlawdNexus::Builder->new(
            config_file => $config_file,
        );
        
        my $nexus = $builder->build();
        my $output_dir = $nexus->config->{output}{path} // './public';
        
        # Make sure site is built
        $nexus->render_all($output_dir);
        
        # Set up server options
        my $port = $opts{port} // $nexus->config->{server}{port} // 8080;
        my $host = $opts{host} // $nexus->config->{server}{host} // 'localhost';
        my $watch = $opts{watch} // $nexus->config->{server}{watch} // 0;
        
        print "Starting server at http://$host:$port\n";
        print "Serving content from $output_dir\n";
        
        # Set up file watcher if requested
        if ($watch) {
            print "Watching for changes. Press Ctrl+C to stop.\n";
            
            my @watch_dirs;
            for my $source (@{$nexus->config->{content}{sources}}) {
                if ($source->{type} eq 'directory') {
                    push @watch_dirs, $source->{path};
                }
            }
            
            # Also watch templates directory
            if (my $template_dir = $nexus->config->{templates}{directory}) {
                push @watch_dirs, $template_dir;
            }
            
            my $watcher = File::Watcher::Simple->new(
                directories => \@watch_dirs,
                filter => qr/\.(md|mdwn|markdown|html|htm|txt|css|js)$/i,
            );
            
            # Watch for changes in a separate thread
            my $watch_thread = threads->create(sub {
                while (1) {
                    if (my @changes = $watcher->changed_files) {
                        print "Changes detected. Rebuilding...\n";
                        $nexus = $builder->build();
                        $nexus->render_all($output_dir);
                        print "Rebuild complete.\n";
                    }
                    sleep 1;
                }
            });
            $watch_thread->detach();
        }
        
        # Create Plack application
        my $app = builder {
            enable 'Plack::Middleware::Static',
                path => qr{^/},
                root => $output_dir;
                
            Plack::App::Directory->new(root => $output_dir)->to_app;
        };
        
        # Run the server
        my $runner = Plack::Runner->new;
        $runner->parse_options(
            '--host' => $host,
            '--port' => $port,
        );
        $runner->run($app);
        
        return 0;
    }
}

package BlawdNexus::Command::New;
use v5.40;
use feature 'class';
use Path::Tiny;
use DateTime;

class BlawdNexus::Command::New :isa(BlawdNexus::Command) {
    method execute(@args) {
        # Parse new-specific options
        my %opts;
        GetOptions(
            \%opts,
            'title|t=s',
            'tags=s',
            'author|a=s',
            'template=s',
        );
        
        # Load builder to get configuration
        my $builder = BlawdNexus::Builder->new(
            config_file => $config_file,
        );
        my $nexus = $builder->build();
        
        # Get title (required)
        my $title = $opts{title} // shift @args;
        unless ($title) {
            die "Error: Title is required. Use --title or provide as first argument.\n";
        }
        
        # Derive filename from title
        my $filename = lc($title);
        $filename =~ s/[^a-z0-9]+/-/g;
        $filename =~ s/^-|-$//g;
        
        # Get other options or use defaults
        my $tags = $opts{tags} // '';
        my $author = $opts{author} // $nexus->config->{site}{author} // 'Unknown';
        
        # Create content from template or default
        my $content;
        if (my $template_name = $opts{template}) {
            my $template_dir = $nexus->config->{templates}{directory} // './templates';
            my $template_file = path($template_dir, "$template_name.md");
            
            if (-f $template_file) {
                $content = $template_file->slurp_utf8;
                
                # Replace template placeholders
                $content =~ s/\{\{title\}\}/$title/g;
                $content =~ s/\{\{author\}\}/$author/g;
                $content =~ s/\{\{date\}\}/DateTime->now->iso8601/ge;
                $content =~ s/\{\{tags\}\}/$tags/g;
            }
            else {
                die "Error: Template '$template_name' not found in $template_dir\n";
            }
        }
        else {
            # Default content
            $content = <<"CONTENT";
---
title: "$title"
author: "$author"
date: @{[DateTime->now->iso8601]}
tags: [$tags]
---

# $title

Write your content here.
CONTENT
        }
        
        # Determine output location
        my $output_path;
        for my $source (@{$nexus->config->{content}{sources}}) {
            if ($source->{type} eq 'directory') {
                $output_path = path($source->{path}, "$filename.md");
                last;
            }
        }
        
        unless ($output_path) {
            die "Error: No valid content directory found in configuration.\n";
        }
        
        # Check if file already exists
        if (-e $output_path) {
            die "Error: File '$output_path' already exists.\n";
        }
        
        # Write the file
        $output_path->parent->mkpath;
        $output_path->spew_utf8($content);
        
        print "Created new entry at $output_path\n";
        return 0;
    }
}

# Main script entry point
package main;
use v5.40;

# Run the CLI when script is executed
BlawdNexus::CLI->new->run(@ARGV) unless caller;

1;

__END__

=head1 NAME

bn - A modern static site generator with semantic indexing

=head1 SYNOPSIS

  bn [options] command [command-options]

  Commands:
    build     Build the site
    serve     Start a local server and optionally watch for changes
    new       Create a new content entry
    index-entries  Update the semantic database

  Options:
    --help, -h    Show this help message
    --config, -c  Path to configuration file (default: ./bn.yml)
    --verbose, -v Show verbose output

  Examples:
    bn build
    bn serve --port 8080 --watch
    bn new --title "My New Post" --tags "perl,programming"
    bn index-entries --all

=head1 DESCRIPTION

BlawdNexus is a modern static site generator that builds upon the original Blawd  
but updated with Perl 5.40's class feature syntax and enhanced with semantic indexing 
capabilities for sophisticated "related content" suggestions.

=head1 COMMANDS

=head2 build

Build the static site according to configuration.

=head2 serve

Start a local web server to preview the site. Use --watch to automatically 
rebuild when content changes.

=head2 new

Create a new content entry.

  Options:
    --title, -t   Title of the new entry (required)
    --tags        Comma-separated list of tags
    --author, -a  Author name (defaults to config)
    --template    Template to use (from templates directory)

=head2 index-entries

Update the semantic database with content from the site.

  Options:
    --all         Index all entries
    --new         Only index entries not yet in the database
    --indexer-path=PATH   Path to the indexer script
    --db-path=PATH        Path to the semantic database

=head1 CONFIGURATION

See the documentation for details on the bn.yml configuration file format.

=head1 AUTHOR

Chris Prather

=cut