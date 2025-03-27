#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use BlawdNexus::Util qw(slugify format_w3cdtf);
use Time::Piece;
use Time::Local;

# Basic slugify functionality test
subtest 'slugify_basic' => sub {
    is(slugify('Hello World'), 'hello-world', 'Basic slugify works');
    is(slugify('Test123'), 'test123', 'Numbers are preserved');
    is(slugify('  Spaces  '), 'spaces', 'Spaces are trimmed and replaced');
};

# Test specific date handling with format_w3cdtf
subtest 'w3cdtf_format' => sub {
    # Create a fixed date for testing using gmtime to ensure UTC
    my $date = Time::Piece->gmtime(Time::Local::timegm(15, 30, 12, 25, 11, 120)); # 2020-12-25 12:30:15 UTC
    is(format_w3cdtf($date), '2020-12-25T12:30:15Z', 'Date formatted correctly');
    
    # Test with a different date
    my $date2 = Time::Piece->gmtime(Time::Local::timegm(0, 0, 0, 1, 0, 123)); # 2023-01-01 00:00:00 UTC
    is(format_w3cdtf($date2), '2023-01-01T00:00:00Z', 'Another date formatted correctly');
    
    # Check edge cases
    is(format_w3cdtf(undef), undef, 'Undefined returns undef');
};

# Optional parameters for slugify
subtest 'slugify_options' => sub {
    is(slugify('Hello World', max_length => 5), 'hello', 'Max length respected');
    is(slugify('Hello World', separator => '_'), 'hello_world', 'Custom separator works');
};

# Special character handling
subtest 'slugify_special_chars' => sub {
    is(slugify('Café & Bäckerei'), 'cafe-backerei', 'Special characters handled');
    is(slugify('a!@#$%^&*()b'), 'a-b', 'Punctuation removed');
};

done_testing();