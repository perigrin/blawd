#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use Path::Tiny;
use Time::Piece;
use Time::Local;

# Load the Entry modules
use BlawdNexus::Entry;
use BlawdNexus::Entry::MultiMarkdown;

# Test base Entry class
subtest 'Entry Base Class' => sub {
    # Create a fixed date for testing
    my $test_date = Time::Piece->gmtime(Time::Local::timegm(0, 0, 0, 15, 0, 123)); # 2023-01-15
    
    my $entry = BlawdNexus::Entry->new(
        title => 'Test Entry',
        content => 'This is test content',
        author => 'Test Author',
        date => $test_date,
        filename => 'test-entry.md',
        tags => ['test', 'perl'],
    );
    
    # Test accessors
    is($entry->title, 'Test Entry', 'Title is set correctly');
    is($entry->content, 'This is test content', 'Content is set correctly');
    is($entry->author, 'Test Author', 'Author is set correctly');
    ok(ref($entry->date) eq 'Time::Piece', 'Date is a Time::Piece object');
    is($entry->date->ymd, '2023-01-15', 'Date is set correctly');
    is($entry->filename, 'test-entry.md', 'Filename is set correctly');
    is($entry->filename_base, 'test-entry', 'Filename base is correct');
    is($entry->tags, ['test', 'perl'], 'Tags are set correctly');
    
    # Test has_tag method
    ok($entry->has_tag('test'), 'has_tag returns true for existing tag');
    ok(!$entry->has_tag('nonexistent'), 'has_tag returns false for nonexistent tag');
    
    # Test body method (defaults to content for base class)
    is($entry->body, 'This is test content', 'Body returns content for base class');
    
    # Test as_hash method
    my $hash = $entry->as_hash;
    is($hash->{title}, 'Test Entry', 'as_hash includes title');
    is($hash->{author}, 'Test Author', 'as_hash includes author');
    is($hash->{filename}, 'test-entry.md', 'as_hash includes filename');
    is($hash->{body}, 'This is test content', 'as_hash includes body');
};

# Test MultiMarkdown Entry class
subtest 'MultiMarkdown Entry Class' => sub {
    # Create test content directly instead of using a file
    my $markdown_content = <<'MARKDOWN';
---
title: Markdown Test
author: Markdown Author
date: 2023-02-20
tags: [markdown, test, multi]
custom_field: custom value
---

# Markdown Test

This is a **markdown** test with some *formatting*.

- List item 1
- List item 2
MARKDOWN

    # Create the entry with our markdown content
    my $entry = BlawdNexus::Entry::MultiMarkdown->new(
        content => $markdown_content,
        filename => 'test-markdown.md',
    );
    
    # Access the body to trigger frontmatter parsing
    my $body = $entry->body;
    
    # Test front matter parsing
    is($entry->title, 'Markdown Test', 'Title parsed from front matter');
    is($entry->author, 'Markdown Author', 'Author parsed from front matter');
    ok(ref($entry->date) eq 'Time::Piece', 'Date is a Time::Piece object');
    like($entry->date->ymd, qr/^\d{4}-\d{2}-\d{2}$/, 'Date parsed from front matter has correct format');
    is($entry->tags, array { item('markdown'); item('test'); item('multi'); end; }, 'Tags parsed from front matter');
    
    # Test custom metadata
    my $metadata = $entry->metadata;
    is($metadata->{custom_field}, 'custom value', 'Custom metadata field parsed');
    
    # Test body extraction
    like($entry->body, qr/# Markdown Test/, 'Body extracted correctly');
    like($entry->body, qr/This is a \*\*markdown\*\* test/, 'Body includes markdown content');
    
    # Test HTML rendering
    my $html = $entry->render_html;
    like($html, qr{<h1>Markdown Test</h1>}, 'HTML rendering includes h1');
    like($html, qr{<strong>markdown</strong>}, 'HTML rendering converts markdown to HTML');
    like($html, qr{<li>List item 1</li>}, 'HTML rendering includes list items');
    
    # Test with no front matter
    my $simple_content = "# No Front Matter\n\nThis has no front matter.";
    my $test_date = Time::Piece->gmtime(Time::Local::timegm(0, 0, 0, 15, 2, 123)); # 2023-03-15
    
    my $no_front_entry = BlawdNexus::Entry::MultiMarkdown->new(
        content => $simple_content,
        filename => 'no-front.md',
        author => 'Default Author',
        date => $test_date,
    );
    
    is($no_front_entry->title, '', 'Title defaults to empty with no front matter');
    is($no_front_entry->author, 'Default Author', 'Author defaults to constructor value');
    is($no_front_entry->body, "# No Front Matter\n\nThis has no front matter.", 'Body is full content with no front matter');
    
    # Test is_valid_file class method
    ok(BlawdNexus::Entry::MultiMarkdown->is_valid_file('test.md'), '.md is valid');
    ok(BlawdNexus::Entry::MultiMarkdown->is_valid_file('test.mdwn'), '.mdwn is valid');
    ok(BlawdNexus::Entry::MultiMarkdown->is_valid_file('test.markdown'), '.markdown is valid');
    ok(!BlawdNexus::Entry::MultiMarkdown->is_valid_file('test.txt'), '.txt is not valid');
};

done_testing();