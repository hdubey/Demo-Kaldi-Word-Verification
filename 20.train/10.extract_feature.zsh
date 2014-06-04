#!/usr/bin/env zsh
# vim: fdm=syntax
# Extract training feature
#***************************************************************************\
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
#***************************************************************************/

function extract_feature {
  mkdir -p feat
  mkdir -p log tmp
  local DEMO_LOG=log/extract_feature.log

  (echo; echo "DO FEATURE EXTRACTION $(getDateStamp)"; echo) >> $DEMO_LOG

  cat ../config/aurora4_multi.scp \
    | adddir.pl $CORPUS_AURORA4/ .wav \
    > tmp/train.scp || exit 1
  split_lists.zsh $DEMO_NPARV $DEMO_NPARDIGIT \
    tmp/train.scp tmp/train.scp.part || exit 1

  for z in ${(f)DEMO_FORPARV}; do # {{{
    runBG "MFCC" $z "compute-mfcc-feats \
      --window-type=hamming --raw-energy=false --dither=0 \
      --use-energy=false --num-mel-bins=23 --sample-frequency=16000 \
      scp,o,s,cs:tmp/train.scp.part$z ark:tmp/feat_mfcc.ark.part$z"
  done; wait # }}}

  for z in ${(f)DEMO_FORPARV}; do # {{{
    runBG "CMVN" $z "compute-cmvn-stats \
      ark,o,s,cs:tmp/feat_mfcc.ark.part$z ark:- \
      | apply-cmvn --norm-vars=true ark:- \
      ark,o,s,cs:tmp/feat_mfcc.ark.part$z \
      ark:tmp/feat_cmvn.ark.part$z"
  done; wait # }}}

  cat tmp/feat_cmvn.ark.part* \
    | ( copy-feats --compress=false ark,o,s,cs:- \
    ark:- 2>> $DEMO_LOG || exit 1) \
    | gzip -c > feat/cmvn.ark.gz
}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
extract_feature
