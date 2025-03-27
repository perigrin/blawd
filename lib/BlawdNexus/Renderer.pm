package BlawdNexus::Renderer;
use v5.40;
use experimental 'class';
use Path::Tiny;

class BlawdNexus::Renderer {
    field $extension :param :reader = '.html';
    field $base_uri :param :reader = '/';
    field $config :param :reader = {};
    
    # Setter methods
    method set_extension($value) { $extension = $value }
    method set_base_uri($value) { $base_uri = $value }
    method set_config($value) { $config = $value }
    
    method render_entry($entry) {
        die "Abstract method 'render_entry' must be implemented by subclass";
    }
    
    method render_entry_fragment($entry) {
        die "Abstract method 'render_entry_fragment' must be implemented by subclass";
    }
    
    method render_index($index) {
        die "Abstract method 'render_index' must be implemented by subclass";
    }
    
    method render_index_fragment($index) {
        die "Abstract method 'render_index_fragment' must be implemented by subclass";
    }
    
    # Generic render method that dispatches to the appropriate specific method
    method render($renderable) {
        if ($renderable->isa('BlawdNexus::Entry')) {
            return $self->render_entry($renderable);
        }
        elsif ($renderable->isa('BlawdNexus::Index')) {
            return $self->render_index($renderable);
        }
        else {
            die "Don't know how to render " . ref($renderable);
        }
    }
    
    method render_to_file($path, $renderable) {
        my $content = $self->render($renderable);
        path($path)->parent->mkpath;  # Create parent directories if they don't exist
        path($path)->spew_utf8($content);
        return 1;
    }
}

1;
