#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use Time::Piece;
use Time::Local;
use BlawdNexus::Util qw(format_w3cdtf);

# For our tests, we'll create fixed test dates rather than using current time
# This makes our tests deterministic

subtest 'w3cdtf_basic_functionality' => sub {
    # Specific date/time using timegm for UTC times
    my $tp = Time::Piece->gmtime(Time::Local::timegm(30, 15, 10, 25, 5, 123));  # 2023-06-25 10:15:30 UTC
    is(format_w3cdtf($tp), '2023-06-25T10:15:30Z', 'Basic date/time formatted correctly');
    
    # Current time in UTC for consistent testing
    my $now = Time::Piece->gmtime;
    like(format_w3cdtf($now), qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, 'Current time has correct format');
    
    # Epoch start (1970-01-01 UTC)
    my $epoch = Time::Piece->gmtime(0);  # Ensure UTC time
    is(format_w3cdtf($epoch), '1970-01-01T00:00:00Z', 'Epoch start formatted correctly');
    
    # Future date
    my $future = Time::Piece->gmtime(Time::Local::timegm(0, 0, 0, 1, 0, 130));  # 2030-01-01 00:00:00 UTC
    is(format_w3cdtf($future), '2030-01-01T00:00:00Z', 'Future date formatted correctly');
    
    # Past date
    my $past = Time::Piece->gmtime(Time::Local::timegm(0, 0, 0, 1, 0, 100));  # 2000-01-01 00:00:00 UTC
    is(format_w3cdtf($past), '2000-01-01T00:00:00Z', 'Past date formatted correctly');
};

subtest 'w3cdtf_edge_cases' => sub {
    # Null/undefined
    is(format_w3cdtf(undef), undef, 'Undefined returns undef');
    
    # Non-Time::Piece object
    is(format_w3cdtf('string'), undef, 'String input returns undef');
    is(format_w3cdtf({}), undef, 'Hash ref input returns undef');
    is(format_w3cdtf([]), undef, 'Array ref input returns undef');
};

subtest 'w3cdtf_usage_in_atom' => sub {
    # Mock usage in Atom feed with a fixed date in UTC
    my $entry_date = Time::Piece->gmtime(Time::Local::timegm(0, 0, 12, 15, 3, 123));  # 2023-04-15 12:00:00 UTC
    my $w3c_date = format_w3cdtf($entry_date);
    
    is($w3c_date, '2023-04-15T12:00:00Z', 'Date format for Atom feed correct');
    
    # XML fragments would use this format
    my $xml = qq{<published>$w3c_date</published>};
    like($xml, qr/<published>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z<\/published>/, 'XML fragment format correct');
};

done_testing();
