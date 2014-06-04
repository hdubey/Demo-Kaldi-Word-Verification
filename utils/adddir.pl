#!/usr/bin/env perl
# Add dir and extension to a file list
#***************************************************************************
# Copyright 2011-2014, Yu-chen Kao
#
# Licensed under the Academic Free License, Version 3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at the root directory of this
# software project or at:
#
#     http://opensource.org/licenses/AFL-3.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#***************************************************************************

use strict;
use warnings;

my $USAGE = "Usage: adddir.pl prefix postfix [input] > output";

if (@ARGV < 2) {
  print STDERR "$USAGE\n";
}

my $prefix = $ARGV[0];
my $postfix = $ARGV[1];
shift @ARGV; shift @ARGV;

while(<>) {
  my $thisline = $_;
  # Trimming whitespaces
  $thisline =~ s/^\s+//;
  $thisline =~ s/\s+$//;
  next if (length($thisline) == 0);

  $thisline =~ s/^([^ ]+) (.*)$/$1 $prefix$2$postfix/;
  print "$thisline\n"
}
