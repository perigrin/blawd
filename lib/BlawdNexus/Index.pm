package BlawdNexus::Index;
use v5.40;
use experimental 'class';
use Path::Tiny;

class BlawdNexus::Index {
    field $title :param :reader;
    field $filename :param :reader;
    field $entries :param :reader;
    field $config :param :reader = {};
    
    method filename_base {
        return path($filename)->basename(qr/\.\w+$/);
    }
    
    method size {
        return scalar(@$entries);
    }
    
    method render($renderer) {
        return $renderer->render_index($self);
    }
    
    method render_fragment($renderer) {
        return $renderer->render_index_fragment($self);
    }
    
    method as_hash {
        return {
            title => $title,
            filename => $filename,
            entry_count => $self->size,
            config => $config,
        };
    }
}

1;
