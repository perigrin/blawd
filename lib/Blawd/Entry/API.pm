package Blawd::Entry::API;
use Blawd::OO::Role;
use MooseX::Types::DateTime qw(DateTime);
use List::MoreUtils qw(any);

with qw( Blawd::Renderable );

has storage_author => (
    isa        => 'Str',
    is         => 'ro',
);

has author => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has storage_date => (
    isa        => DateTime,
    is         => 'ro',
    coerce     => 1,
);

has date => (
    isa        => DateTime,
    is         => 'ro',
    coerce     => 1,
    lazy_build => 1
);

has content => (
    isa        => 'Str',
    is         => 'ro',
    required   => 1,
);

has body => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has tags => (
    isa        => 'ArrayRef[Str]',
    is         => 'ro',
    lazy_build => 1,
);

requires qw(
  _build_author
  _build_date
  _build_tags
);

sub _build_body { shift->content }

sub has_tag {
    my $self = shift;
    my ($tag) = @_;
    return any { $_ eq $tag } @{ $self->tags };
}

sub render_page_default     { shift->body }
sub render_fragment_default { shift->body }

1;
__END__
