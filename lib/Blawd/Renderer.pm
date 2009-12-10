package Blawd::Renderer;
use Module::Pluggable (
    require     => 1,
    sub_name    => 'renderers',
    search_path => [__PACKAGE__],
    except      => qr/Meta|Role|API/,
);

1;
