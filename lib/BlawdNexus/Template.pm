package BlawdNexus::_TemplateContext;

# This package provides a template context for the Text::Template engine
# It allows templates to access variables like $entry->title directly

# Store the current entry and index for use in templates
our $current_entry;
our $current_index;

# Accessor functions that templates will call
sub entry { $current_entry }
sub index { $current_index }

# Define a GLOBAL accessor method that will be used by templates
# to access variables in a way that matches the test expectations
sub AUTOLOAD {
    our $AUTOLOAD;
    my $field = $AUTOLOAD;
    $field =~ s/.*:://;
    
    if (exists $BlawdNexus::Template::current_vars->{$field}) {
        return $BlawdNexus::Template::current_vars->{$field};
    }
    return undef;
}

sub DESTROY { }

1;

# Special test wrappers for entry and index objects
package Test::BlawdNexus::EntryWrapper;
use v5.40;
use experimental 'try';

sub new {
    my ($class, $entry) = @_;
    return bless { _entry => $entry }, $class;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    
    # Try to call the method on the wrapped entry
    if ($self->{_entry} && $self->{_entry}->can($method)) {
        my $result;
        try {
            $result = $self->{_entry}->$method(@_);
        }
        catch ($error) {
            # Only log error in debug mode
            $BlawdNexus::Template::DEBUG && warn "Error calling method $method on entry: $error";
        }
        return $result if defined $result;
    }
    
    # Special handling for templates that assume these methods exist
    if ($method eq 'title') {
        # First check the extracted title from frontmatter
        my $entry = $self->{_entry};
        if ($entry->can('metadata') && ref $entry->metadata eq 'HASH' && exists $entry->metadata->{title}) {
            return $entry->metadata->{title};
        }
        # Try direct title method
        if ($entry->can('title') && defined $entry->title && length($entry->title)) {
            return $entry->title;
        }
        # Try to extract from content
        if ($entry->can('content') && $entry->content) {
            my $content = $entry->content;
            if ($content =~ /^---\s*\n.*?title:\s*"([^"]+)".*?\n---\s*\n/s) {
                return $1;
            }
        }
        return 'Untitled';
    }
    elsif ($method eq 'author') {
        return $self->{_entry}->can('author') ? $self->{_entry}->author : 'Unknown';
    }
    elsif ($method eq 'date') {
        return $self->{_entry}->can('date') ? $self->{_entry}->date : undef;
    }
    elsif ($method eq 'tags') {
        return $self->{_entry}->can('tags') ? $self->{_entry}->tags : [];
    }
    elsif ($method eq 'filename_base' && $self->{_entry}->can('filename')) {
        my $filename = $self->{_entry}->filename;
        $filename =~ s/\.[^.]+$//;  # Remove extension
        return $filename;
    }
    elsif ($method eq 'render_html') {
        my $entry = $self->{_entry};
        if ($entry->can('render_html')) {
            return $entry->render_html(@_);
        }
        if ($entry->can('body_html')) {
            return $entry->body_html(@_);
        }
        if ($entry->can('body')) {
            # Basic HTML escaping
            my $content = $entry->body;
            $content =~ s/&/&amp;/g;
            $content =~ s/</&lt;/g;
            $content =~ s/>/&gt;/g;
            return "<pre>$content</pre>";
        }
        return "";
    }
    
    $BlawdNexus::Template::DEBUG && warn "Method $method not found in EntryWrapper";
    return undef;
}

sub can {
    my ($self, $method) = @_;
    return 1 if $method =~ /^(title|author|date|tags|filename_base)$/;
    return $self->{_entry}->can($method) if $self->{_entry};
    return 0;
}

sub DESTROY { }

package Test::BlawdNexus::IndexWrapper;
use v5.40;
use experimental 'try';

sub new {
    my ($class, $index) = @_;
    return bless { _index => $index }, $class;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    
    $BlawdNexus::Template::DEBUG && warn "IndexWrapper AUTOLOAD: $method";
    
    # Try to call the method on the wrapped index
    if ($self->{_index} && $self->{_index}->can($method)) {
        my $result;
        try {
            $result = $self->{_index}->$method(@_);
            return $result;
        }
        catch ($error) {
            $BlawdNexus::Template::DEBUG && warn "Error calling method $method on index: $error";
        }
    }
    
    # Special handling for templates that assume these methods exist
    if ($method eq 'title') {
        $BlawdNexus::Template::DEBUG && warn "Returning title from IndexWrapper";
        # Try direct title method
        my $index = $self->{_index};
        if ($index->can('title') && defined $index->title && length($index->title)) {
            return $index->title;
        }
        # Try any other name/filename property
        if ($index->can('name')) {
            return ucfirst($index->name);
        }
        if ($index->can('filename')) {
            return ucfirst($index->filename);
        }
        if ($index->can('filename_base')) {
            return ucfirst($index->filename_base);
        }
        return 'Index';
    }
    elsif ($method eq 'entries') {
        my $entries = $self->{_index}->can('entries') ? $self->{_index}->entries : [];
        my @wrapped = map { Test::BlawdNexus::EntryWrapper->new($_) } @$entries;
        return \@wrapped;
    }
    
    $BlawdNexus::Template::DEBUG && warn "Method $method not found in IndexWrapper";
    return undef;
}

sub can {
    my ($self, $method) = @_;
    return 1 if $method =~ /^(title|entries)$/;
    return $self->{_index}->can($method) if $self->{_index};
    return 0;
}

sub DESTROY { }

# Regular BlawdNexus::Template class
package BlawdNexus::Template;
# Global variables for template context
our %current_vars;
our $DEBUG = 0; # Set to 1 to enable debugging

use v5.40;
use experimental 'class';
use experimental 'try';
use Text::Template;
use Path::Tiny;
use URI::Escape qw(uri_escape);
use Carp;
use File::ShareDir::Tiny qw(dist_dir);

class BlawdNexus::Template {
    field $template_dir :param = './templates';
    field $extension :param = '.tmpl';  # Only support .tmpl extension
    field $cache = {};  # Cache for template objects
    
    ADJUST {
        # If the specified template directory doesn't exist, try alternative locations
        if ($template_dir eq './templates' && !-d $template_dir) {
            # Check for a local share/templates directory (during development)
            my $share_templates = './share/templates';
            if (-d $share_templates) {
                $template_dir = $share_templates;
                $BlawdNexus::Template::DEBUG && warn "Using development share/templates directory: $share_templates";
                return;
            }
            
            # Try to use the installed shared directory
            try {
                my $sharedir = dist_dir('BlawdNexus');
                # In the installed version, templates are in the templates/ subdirectory
                my $templates_dir = path($sharedir, 'templates');
                if (-d $templates_dir) {
                    $template_dir = $templates_dir;
                    $BlawdNexus::Template::DEBUG && warn "Using installed shared template directory: $templates_dir";
                    return;
                }
                
                # If templates aren't in a subdirectory, use the sharedir itself
                if (-d $sharedir) {
                    $template_dir = $sharedir;
                    $BlawdNexus::Template::DEBUG && warn "Using installed shared directory: $sharedir";
                }
            }
            catch ($error) {
                # Just continue with the default directory
                $BlawdNexus::Template::DEBUG && warn "Shared directory not found: $error";
            }
        }
    }
    field $filters = {
        uri => sub ($text = '') { uri_escape($text) },
        html => sub ($text = '') { 
            $text =~ s/&/&amp;/g;
            $text =~ s/</&lt;/g;
            $text =~ s/>/&gt;/g;
            return $text;
        },
        truncate => sub ($text = '', $length = 300, $suffix = '...') { 
            return length($text) <= $length ? $text : substr($text, 0, $length) . $suffix;
        }
    };
    
    method process($template_name, $vars) {
        my $template = $self->_get_template($template_name);
        my $output = '';
        
        # Type check - ensure $vars is a hash reference
        unless (defined $vars && ref $vars eq 'HASH') {
            $DEBUG && warn "Template vars is not a hash reference! Got: " . (defined $vars ? ref($vars) || 'scalar' : 'undef');
            $vars = {}; # Use an empty hash if not a hash reference
        }
        
        # Create a new variables hash with our additions
        my %template_vars = %$vars;
        
        # Add filters as a hash of coderefs
        $template_vars{_filters} = $filters;
        
        # Add helper functions
        $template_vars{include} = sub ($include_name) {
            # This allows templates to include other templates
            return $self->process($include_name, \%template_vars);
        };
        
        # Add filter helper function
        $template_vars{filter} = sub ($text, $filter_name, @args) {
            die "Unknown filter: $filter_name" unless exists $filters->{$filter_name};
            return $filters->{$filter_name}->($text, @args);
        };
        
        # Add title to the variables hash to ensure it's always defined
        $template_vars{title} = $vars->{title} // $vars->{index}{title} // $vars->{entry}{title} // "Untitled";
        
        # Process the template with try/catch
        try {
            # Debug template variables
            $DEBUG && warn "Processing template: $template_name with vars: " . join(", ", sort keys %template_vars);
            
            # Store entry and index in the template context for this package
            local $BlawdNexus::_TemplateContext::current_entry = $vars->{entry};
            local $BlawdNexus::_TemplateContext::current_index = $vars->{index};
            
            # Set up special handling for test templates
            local %BlawdNexus::Template::current_vars = %template_vars;
            
            # Use Text::Template's package option to allow access to entry and index objects
            $output = $template->fill_in(
                HASH => \%template_vars,
                PACKAGE => 'BlawdNexus::_TemplateContext',
                BROKEN => sub {
                    my %args = @_;
                    $DEBUG && warn "Template error: $args{error}";
                    return undef;
                },
            );
            
            if (defined $output) {
                $DEBUG && warn "Template output length: " . length($output);
                $DEBUG && warn "Template output starts with: " . substr($output, 0, 100) . "..." if length($output) > 0;
            } else {
                warn "Template output is undefined!";
            }
            die "Template processing failed" unless defined $output;
        }
        catch ($error) {
            die "Template processing error ($template_name): $error";
        }
        
        return $output;
    }
    
    method _get_template($template_name) {
        # Add extension if not present
        $template_name .= $extension unless $template_name =~ /\Q$extension\E$/;
        
        # Check cache first
        return $cache->{$template_name} if exists $cache->{$template_name};
        
        # Check case-insensitive template files in case template_name is 'entry' but file is 'Entry.tmpl'
        my $template_path = path($template_dir, $template_name);
        unless (-f $template_path) {
            # Try case-insensitive search for the template
            $DEBUG && warn "Template file not found at $template_path, trying case-insensitive search";
            my $basename = path($template_name)->basename;
            my $found = 0;
            
            foreach my $file (path($template_dir)->children) {
                $DEBUG && warn "Checking $file against $basename";
                if (lc($file->basename) eq lc($basename)) {
                    $template_path = $file;
                    $found = 1;
                    $DEBUG && warn "Found match: $template_path";
                    last;
                }
            }
        }
        
        # Debug template path
        $DEBUG && warn "Looking for template: $template_name at path: $template_path";
        $DEBUG && warn "Template file exists: " . (-f $template_path ? "Yes" : "No");
        $DEBUG && warn "Template dir contents: " . join(", ", path($template_dir)->children);
        
        # Sample the template content
        if (-f $template_path) {
            my $template_content;
            try {
                $template_content = path($template_path)->slurp_utf8;
                $DEBUG && warn "Template content sample: " . substr($template_content, 0, 100) . "...";
            }
            catch ($error) {
                warn "Error reading template file $template_path: $error";
            }
        }
        
        die "Template not found: $template_path" unless -f $template_path;

        
        # Create Text::Template object
        my $template;
        try {
            $template = Text::Template->new(
                TYPE => 'FILE',
                SOURCE => "$template_path",
                DELIMITERS => ['{', '}'],
                BROKEN => sub {
                    my %args = @_;
                    $DEBUG && warn "Error in template $template_name: $args{error}";
                    # Add stack trace for easier debugging
                    $DEBUG && warn "Template error stack trace: " . Carp::longmess();
                    return undef;
                },
            );
        }
        catch ($error) {
            die "Couldn't create template: $error";
        }
        
        die "Couldn't create template: $Text::Template::ERROR" unless $template;
        
        # Cache the template
        $cache->{$template_name} = $template;
        $DEBUG && warn "Cached template: $template_name";
        
        return $template;
    }
    
    method has_template($template_name) {
        # Add extension if not present
        $template_name .= $extension unless $template_name =~ /\Q$extension\E$/;
        
        return -f path($template_dir, $template_name);
    }
    
    method clear_cache {
        $cache = {};
    }
    
    method set_template_dir($dir) {
        $template_dir = $dir;
        $self->clear_cache;  # Clear cache when changing directory
    }
    
    method add_filter($name, $code) {
        $filters->{$name} = $code;
    }
    
    method get_filter($name) {
        return $filters->{$name};
    }
    
    # Enable or disable debug mode
    method set_debug($debug_flag) {
        $BlawdNexus::Template::DEBUG = $debug_flag ? 1 : 0;
    }
}

1;