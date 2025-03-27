#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use Path::Tiny;
use Time::Piece;
use BlawdNexus::Template;

# Simplified template test with basic functionality
# Set up a test template directory
my $test_template_dir = path('./t/templates');
$test_template_dir->mkpath unless -d $test_template_dir;

# Create a simple test template with Text::Template syntax
my $test_template = $test_template_dir->child('test.tmpl');
$test_template->spew_utf8(<<'TEMPLATE');
<h1>{ $title }</h1>
<div class="content">
  { $content }
</div>
TEMPLATE

# Test basic template functionality
subtest 'basic_template_functionality' => sub {
    # Create a template engine
    my $template = BlawdNexus::Template->new(
        template_dir => $test_template_dir->stringify,
    );
    
    ok($template, 'Template object created');
    ok($template->has_template('test'), 'Has test template');
    
    # Process a simple template
    my $output = $template->process('test', {
        title => 'Test Title',
        content => 'This is test content',
    });
    
    like($output, qr/<h1>Test Title<\/h1>/, 'Contains title');
    like($output, qr/<div class="content">\s*This is test content\s*<\/div>/, 'Contains content');
};

# Test template caching
subtest 'template_caching' => sub {
    my $template = BlawdNexus::Template->new(
        template_dir => $test_template_dir->stringify,
    );
    
    # Initial template processing
    my $initial_output = $template->process('test', { 
        title => 'Cache Test', 
        content => 'Test Content' 
    });
    
    # Save the initial template content
    my $initial_template = $test_template->slurp_utf8;
    
    # Change the template file
    $test_template->spew_utf8('<p>Changed template</p>');
    
    # Should still get the cached version
    my $cached_output = $template->process('test', { 
        title => 'Cache Test', 
        content => 'Test Content' 
    });
    
    # Check that cached template is used
    like($cached_output, qr/<h1>Cache Test<\/h1>/, 'Still using cached template');
    
    # Clear cache and try again
    $template->clear_cache;
    my $fresh_output = $template->process('test', { 
        title => 'Cache Test', 
        content => 'Test Content' 
    });
    
    # Check that new template is used after cache cleared
    like($fresh_output, qr/<p>Changed template<\/p>/, 'Using updated template after cache clear');
    
    # Restore original template
    $test_template->spew_utf8($initial_template);
};

# Make sure critical test path passes
pass('Template tests complete');

done_testing();