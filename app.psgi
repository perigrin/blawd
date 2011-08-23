#!/usr/bin/env perl
use strict;
use 5.10.1;
use lib qw(lib);

use Encode;

use Plack::Request;
use Plack::Response;

use Blawd::Storage;
use Blawd::Cmd::Container;

my $repo = '/Users/perigrin/dev/the-room/.git/';

my $app = sub {
    my $req = Plack::Request->new(@_);
    my $res = handle_request($req);
    return $res->finalize;
};

sub handle_request {
    my ($req) = @_;
    my $storage = Blawd::Storage->create_storage($repo);
    my $container = Blawd::Cmd::Container->new( storage => $storage );

    my $blawd    = $container->build_app();
    my $renderer = $blawd->get_renderer('HTML');
    my $res = Plack::Response->new( 200, { Content_Type => 'text/html' } );
    given ( $req->path ) {
        $_ =~ s|^/||;
        when ('site.css') {
            my $css = q[
                html {
                    background-color: grey;
                }
                body {
                    width: 900px;
                    background: white;
                    border: 1px solid black;
                    padding-left: 25px;
                    padding-right: 25px;
                }
            ];
            $res->content_type('text/css');
            $res->body( encode_utf8 $css);
            return $res;
        }
        $_ =~ s|\..*?$||;
        when ( $blawd->get_entry($_) ) {
            my $entry = $blawd->get_entry($_);
            $res->body( encode_utf8 $renderer->render_page($entry) );
            return $res;
        }
        when ( $blawd->get_index($_) ) {
            my $index = $blawd->get_index($_);
            $res->body( encode_utf8 $renderer->render_page($index) );
            return $res;
        }
        default {
            my $index = $blawd->get_index('index');
            $res->body( encode_utf8 $renderer->render_page($index) );
            return $res;
        }
    }
}
