#!/usr/bin/env perl
# Pick WSJ transcriptions according to utterance id
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

my $USAGE = "Usage: wsj_pick_transcription.pl scp [input] > output";

if (@ARGV < 1) {
  print STDERR "$USAGE\n";
  exit 5;
}
my $scpfile = shift @ARGV;
my %alltrans;

while(<>) {
  my $thisline = $_;
  # Trimming whitespaces
  $thisline =~ s/^\s+//;
  $thisline =~ s/\s+$//;
  next if (length($thisline) == 0);
  next if (substr($thisline,0,1) eq "#");

  if ($thisline =~ /(.*) \(([a-z0-9]+)\)$/) {
    $alltrans{$2} = $1;
  }
}

open(SCP, $scpfile);
while(<SCP>) {
  my $thisline = $_;
  # Trimming whitespaces
  $thisline =~ s/^\s+//;
  $thisline =~ s/\s+$//;
  next if (length($thisline) == 0);

  if ($thisline =~ /^([^ ]+)_([^ _]+) .*/) {
    print $1 . "_" . $2 . " " . $alltrans{$2} . "\n";
  }
}
