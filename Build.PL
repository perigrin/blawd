#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Module::Build::Tiny;

# Module::Build::Tiny automatically uses:
# - share/ directory for distribution sharedir
#  - Templates are in share/templates/ directory
#  - Will be installed to the appropriate location where File::ShareDir can find them

# Module::Build::Tiny is much simpler than Module::Build
# This two-line script is all that's needed to bootstrap the build
Build_PL();
