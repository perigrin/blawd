#!/usr/bin/env perl
use v5.40;
use Test2::V0;
use Path::Tiny;
use BlawdNexus::Plugin;

# Test basic plugin functionality
{
    package TestPlugin;
    use v5.40;
    use experimental 'class';
    
    class TestPlugin :isa(BlawdNexus::Plugin) {
        field $process_count = 0;
        field $init_count = 0;
        
        method process($content, $context) {
            # Call parent implementation to check if enabled
            return $content unless $self->enabled;
            $process_count++;
            return $content . "<!-- Processed by TestPlugin -->";
        }
        
        method initialize($nexus) {
            $init_count++;
            return 1;
        }
        
        method get_process_count { return $process_count }
        method get_init_count { return $init_count }
    }
}

# Create a plugin instance
my $plugin = TestPlugin->new(
    name => 'Test',
    options => {
        test_option => 'test_value',
        numeric_option => 42,
    },
);

# Test basic properties
ok($plugin, 'Plugin created');
is($plugin->name, 'Test', 'Name is set correctly');
ok($plugin->enabled, 'Plugin enabled by default');

# Test option handling
is($plugin->get_option('test_option'), 'test_value', 'String option accessible');
is($plugin->get_option('numeric_option'), 42, 'Numeric option accessible');
is($plugin->get_option('nonexistent'), undef, 'Nonexistent option returns undef');
is($plugin->get_option('nonexistent', 'default'), 'default', 'Default value works');

# Test process method
my $content = '<div>Test content</div>';
my $context = { test => 'value' };
my $processed = $plugin->process($content, $context);
is($plugin->get_process_count, 1, 'Process was called once');
like($processed, qr/<!-- Processed by TestPlugin -->$/, 'Content was modified');

# Test initialize method
my $mock_nexus = {};
ok($plugin->initialize($mock_nexus), 'Initialize returns true');
is($plugin->get_init_count, 1, 'Initialize was called once');

# Test enabling/disabling
$plugin->disable;
ok(!$plugin->enabled, 'Plugin was disabled');
$plugin->enable;
ok($plugin->enabled, 'Plugin was re-enabled');

# Process doesn't run when disabled
$plugin->disable;
my $unchanged = $plugin->process('test', {});
is($plugin->get_process_count, 1, 'Process not called when disabled');
is($unchanged, 'test', 'Content unchanged when plugin disabled');

# Test lifecycle hook defaults in base class
my $base_plugin = BlawdNexus::Plugin->new(name => 'Base');
can_ok($base_plugin, qw(before_build after_build before_render after_render));

# Test abstract methods
eval { $base_plugin->process('test', {}) };
like($@, qr/must be implemented/, 'Abstract method throws error');

done_testing();