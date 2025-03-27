#!/usr/bin/env perl
use v5.40;
use Test2::V0;

# This test verifies that all modules load correctly

# Core modules
use BlawdNexus;
use BlawdNexus::Entry;
use BlawdNexus::Entry::MultiMarkdown;
use BlawdNexus::Index;
use BlawdNexus::Index::Archive;
use BlawdNexus::Index::Tag;
use BlawdNexus::Index::Semantic;
use BlawdNexus::Renderer;
use BlawdNexus::Renderer::HTML;
use BlawdNexus::Renderer::RSS;
use BlawdNexus::Renderer::Atom;
use BlawdNexus::Renderer::JSON;
use BlawdNexus::App;
use BlawdNexus::Builder;
use BlawdNexus::CLI;
use BlawdNexus::Template;
# Text::Template is now used instead of BlawdNexus::Template::Engine
use Text::Template;
use BlawdNexus::Util;

# Plugin system
use BlawdNexus::Plugin;
use BlawdNexus::Plugin::RelatedContent;
use BlawdNexus::Plugin::SemanticRecommendations;
use BlawdNexus::Plugin::SemanticMap;

# Semantic system
use BlawdNexus::Semantic::Analyzer;
use BlawdNexus::Semantic::Adapter::Indexer;

# File watching
use BlawdNexus::FileWatcher;
use BlawdNexus::FileWatcher::Polling;

# Command system
use BlawdNexus::Command;
use BlawdNexus::Command::Build;
use BlawdNexus::Command::New;
use BlawdNexus::Command::IndexEntries;

# Check version
ok($BlawdNexus::VERSION, 'BlawdNexus version is defined');

pass('All modules loaded successfully');

done_testing();
