#!/usr/bin/env perl
use v5.40;
use experimental 'class', 'try';
use Test2::V0;
use lib '/Users/perigrin/dev/blawd/lib';
use BlawdNexus::Util qw(parse_date);
use Time::Piece;

# Debug flag - set to 0 to reduce test output
my $DEBUG = 0;

# Test various ISO 8601 date formats
my $test_dates = [
    {
        name => 'ISO8601 with timezone offset',
        input => '2023-04-15T15:45-05:00',
        expected => {
            year => 2023,
            month => 4,
            day => 15,
        }
    },
    {
        name => 'ISO8601 without seconds',
        input => '2023-04-15T15:45',
        expected => {
            year => 2023,
            month => 4,
            day => 15,
        }
    },
    {
        name => 'ISO8601 with seconds',
        input => '2023-04-15T15:45:30',
        expected => {
            year => 2023,
            month => 4,
            day => 15,
        }
    },
    {
        name => 'ISO8601 date only',
        input => '2023-04-15',
        expected => {
            year => 2023,
            month => 4,
            day => 15,
        }
    },
    {
        name => 'ISO8601 with timezone +00:00',
        input => '2023-04-15T15:45:30+00:00',
        expected => {
            year => 2023,
            month => 4,
            day => 15,
        }
    },
    {
        name => 'ISO8601 with timezone Z',
        input => '2023-04-15T15:45:30Z',
        expected => {
            year => 2023,
            month => 4,
            day => 15,
        }
    },
];

# Run tests for each date format
foreach my $test (@$test_dates) {
    subtest $test->{name} => sub {
        my $result = parse_date($test->{input});

        # Check that we got a Time::Piece object
        ok($result isa Time::Piece, 'parse_date returns a Time::Piece object');

        # Check the date components
        is($result->year, $test->{expected}{year}, "Year is $test->{expected}{year}");
        is($result->mon, $test->{expected}{month}, "Month is $test->{expected}{month}");
        is($result->mday, $test->{expected}{day}, "Day is $test->{expected}{day}");

        # Helpful debug output - only show when DEBUG is enabled
        $DEBUG && diag(sprintf("Input: %s => Parsed: %04d-%02d-%02d %02d:%02d:%02d",
            $test->{input},
            $result->year, $result->mon, $result->mday,
            $result->hour, $result->min, $result->sec));
    };
}

# Test edge cases
subtest 'Numeric timestamp' => sub {
    # April 15, 2023 UTC
    my $timestamp = 1681560000;
    my $result = parse_date($timestamp);

    ok($result isa Time::Piece, 'parse_date returns a Time::Piece object');
    is($result->year, 2023, 'Year is 2023');
    is($result->mon, 4, 'Month is 4');
    is($result->mday, 15, 'Day is 15');
};

subtest 'Current time for undefined input' => sub {
    my $now = localtime;
    my $result = parse_date(undef);

    ok($result isa Time::Piece, 'parse_date returns a Time::Piece object');
    is($result->year, $now->year, 'Year matches current year');
    is($result->mon, $now->mon, 'Month matches current month');
    is($result->mday, $now->mday, 'Day matches current day');
};

subtest 'Invalid date format' => sub {
    my $now = localtime;
    my $result = parse_date('not-a-date');

    ok($result isa Time::Piece, 'parse_date returns a Time::Piece object even with invalid input');
    is($result->year, $now->year, 'Year matches current year for invalid input');
};

# Test that parse_date works with Time::Piece objects
subtest 'Time::Piece passthrough' => sub {
    my $date = parse_date('2023-04-15');
    my $result = parse_date($date);

    ok($result isa Time::Piece, 'parse_date returns a Time::Piece object');
    is($result->year, 2023, 'Year is 2023');
    is($result->mon, 4, 'Month is 4');
    is($result->mday, 15, 'Day is 15');

    # Check that it's the same object (identity check)
    is($result, $date, 'parse_date returns the same Time::Piece object when given one');
};

done_testing();