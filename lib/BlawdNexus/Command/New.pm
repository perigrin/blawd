package BlawdNexus::Command::New;
use v5.40;
use experimental 'class';
use Path::Tiny;
use Time::Piece;
use Getopt::Long;

class BlawdNexus::Command::New :isa(BlawdNexus::Command) {
    method description() {
        return "Create a new content entry";
    }
    
    method usage() {
        return "bn new --title=\"Title\" [--tags=\"tag1,tag2\"] [--author=\"Author\"]";
    }
    method execute(@args) {
        # Parse new-specific options
        my %opts;
        GetOptions(
            \%opts,
            'title|t=s',
            'tags=s',
            'author|a=s',
            'template=s',
            'date|d=s',
        );

        # Load builder to get configuration
        my $builder = BlawdNexus::Builder->new(
            # Use the accessor method to get config file path
            config_file => $self->config_file,
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
        my $author = $opts{author} // $self->config->{site}{author} // 'Unknown';
        my $date = $opts{date} // localtime()->strftime('%Y-%m-%dT%H:%M:%S%z');

        # Create content from template or default
        my $content;
        if (my $template_name = $opts{template}) {
            my $template_dir = $self->config->{templates}{directory} // './templates';
            my $template_file = path($template_dir, "$template_name.md");

            if (-f $template_file) {
                $content = $template_file->slurp_utf8;

                # Replace template placeholders
                $content =~ s/\{\{title\}\}/$title/g;
                $content =~ s/\{\{author\}\}/$author/g;
                $content =~ s/\{\{date\}\}/$date/g;
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
date: $date
tags: [$tags]
---

# $title

Write your content here.
CONTENT
        }

        # Determine output location
        my $output_path;
        for my $source (@{$self->config->{content}{sources}}) {
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

1;
