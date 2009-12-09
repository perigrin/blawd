package Blawd::Page;
use Blawd::OO::Role;

with qw(Blawd::Renderable);

has title => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has [qw(content filename)] => ( isa => 'Str', is => 'ro', required => 1, );
has headers => ( isa => 'Str', is => 'ro', lazy_build => 1 );
sub _build_headers { '' }

has footers => ( isa => 'Str', is => 'ro', lazy_build => 1 );

sub _build_footers {
    q[<script type="text/javascript">
    try {
        var pageTracker = _gat._getTracker("UA-939082-2");
        pageTracker._trackPageview();
    } catch(err) {}
</script>];
}

requires qw(_build_title);

1;
