#!/usr/bin/env perl
# Normalize WSJ labels to delete unnecessary parts and meet CMUdict
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

# This file is a derived work of the following file in the Kaldi project:
#   (Kaldi Root)/egs/wsj/s5/local/normalize_transcript.pl
# which is licensed under the Apache License, Version 2.0,
# by Microsoft Corporation. The license can be downloaded from
#   http://www.apache.org/licenses/LICENSE-2.0.html.
# The source code for Kaldi is available from 
#   http://kaldi.sourceforge.net/.

use strict;
use warnings;

my $USAGE = "Usage: normalize_transcript_wsj.pl noise_word [input] > output";

if (@ARGV < 1) {
  print STDERR "$USAGE\n";
  exit 5;
}
my $noise_word = shift @ARGV;

while(<>) {
    $_ =~ m:^(\S+) (.+): || die "bad line $_";
    my $utt = $1;
    my $trans = $2;
    print "$utt";
    foreach my $w (split (" ",$trans)) {
        $w =~ tr:a-z:A-Z:; # Upcase everything to match the CMU dictionary. .
        $w =~ s:\\::g;      # Remove backslashes.  We don't need the quoting.
        $w =~ s:^\%PERCENT$:PERCENT:; # Normalization for Nov'93 test transcripts.
        $w =~ s:^\.POINT$:POINT:; # Normalization for Nov'93 test transcripts.
        if($w =~ m:^\[\<\w+\]$:  || # E.g. [<door_slam], this means a door slammed in the preceding word. Delete.
           $w =~ m:^\[\w+\>\]$:  ||  # E.g. [door_slam>], this means a door slammed in the next word.  Delete.
           $w =~ m:\[\w+/\]$: ||  # E.g. [phone_ring/], which indicates the start of this phenomenon.
           $w =~ m:\[\/\w+]$: ||  # E.g. [/phone_ring], which indicates the end of this phenomenon.
           $w =~ m:\(?\w+\)?-$: ||  # Partially pronounced words e.g. REVO(LUTIONARY)- (modified by cybeliak)
           $w eq "~" ||        # This is used to indicate truncation of an utterance.  Not a word.
           $w eq ".") {      # "." is used to indicate a pause.  Silence is optional anyway so not much 
                             # point including this in the transcript.
            next; # we won't print this word.
        } elsif($w =~ m:\[\w+\]:) { # Other noises, e.g. [loud_breath].
            print " $noise_word";
        } elsif($w =~ m:^\<([\w\']+)\>$:) {
            # e.g. replace <and> with and.  (the <> means verbal deletion of a word).. but it's pronounced.
            print " $1";
        } elsif($w =~ m:^\*([^\*]+)\*$:) {
            # e.g. replace *and* with and. It's also pronounced (modified by cybeliak)
            print " $1";
        } elsif($w =~ m:^!(\w+)\:(\w*)$:) {
            # e.g. replace words starts with ! and having : (modified by cybeliak)
            print " $1$2";
        } elsif($w =~ m:^!(\w+)$:) {
            # e.g. replace words starts with ! (modified by cybeliak)
            print " $1";
        } elsif($w =~ m:^(\w+)\:(\w*):) {
            # e.g. replace words having : (modified by cybeliak)
            print " $1$2";
        } elsif($w eq "--DASH") {
            print " -DASH";  # This is a common issue; the CMU dictionary has it as -DASH.
        } elsif($w eq "EXISITING") {
            print " EXISTING";  # Typo !? (modified by cybeliak)
        } else {
            print " $w";
        }
    }
    print "\n";
}
