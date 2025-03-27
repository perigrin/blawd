package BlawdNexus::Template_New;
use v5.40;
use experimental 'class';
use experimental 'try';
use Text::Template;
use Path::Tiny;
use URI::Escape qw(uri_escape);

class BlawdNexus::Template_New {
    field $template_dir :param = './templates';
    field $extension :param = '.tmpl';  # New extension for Text::Template files
    field $cache = {};  # Cache for template objects
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
        
        # Process the template with try/catch
        try {
            $output = $template->fill_in(HASH => \%template_vars);
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
        
        # Load from file
        my $template_path = path($template_dir, $template_name);
        
        die "Template not found: $template_path" unless -f $template_path;
        
        # Create Text::Template object
        my $template = Text::Template->new(
            TYPE => 'FILE',
            SOURCE => "$template_path",
            DELIMITERS => ['{', '}'],
            BROKEN => sub {
                my %args = @_;
                warn "Error in template $template_name: $args{error}" if $ENV{DEBUG_TEMPLATE};
                return undef;
            },
        ) or die "Couldn't create template: $Text::Template::ERROR";
        
        # Cache the template
        $cache->{$template_name} = $template;
        
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
}

1;
