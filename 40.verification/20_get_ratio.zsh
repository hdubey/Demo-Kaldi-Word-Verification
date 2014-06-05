#!/usr/bin/env zsh
# vim: fdm=marker
# Run verification
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

function get_ratio {
  mkdir -p log tmp
  local DEMO_LOG=log/get_ratio.log
  local ascale=0.15
  local beam=40
  local wordname=$1
  local filename=$2

  if [[ ! -f tmp/HCLG_filler.tar.gz ]]; then
    ./05_gen_filler.zsh 2>> $DEMO_LOG
  fi

  ./10_gen_graph.zsh $wordname 2>> $DEMO_LOG

  echo utt $filename > tmp/testwav.scp

  # Feature Extraction
  compute-mfcc-feats --window-type=hamming --dither=0 \
    --raw-energy=false --use-energy=false --num-mel-bins=23 \
    scp:tmp/testwav.scp ark:tmp/mfcc.ark 2>> $DEMO_LOG
  compute-cmvn-stats ark:tmp/mfcc.ark ark:- 2>> $DEMO_LOG \
    | apply-cmvn --norm-vars=true ark:- ark:tmp/mfcc.ark ark:- 2>> $DEMO_LOG \
    | add-deltas --delta-order=2 --delta-window=2 ark:- ark:tmp/feat.ark 2>> $DEMO_LOG

  gmm-decode-faster --acoustic-scale=$ascale --allow-partial=true --beam=$beam \
    ../model/model.mdl "gunzip -c tmp/HCLG.fst.gz |" ark:tmp/feat.ark ark,t:- \
    > /dev/null 2> tmp/log_decode

  local like1=$(grep 'for utterance utt is' tmp/log_decode \
    | sed 's/.* is \([-.0-9]\+\) over.*$/\1/')

  gmm-decode-faster --acoustic-scale=$ascale --allow-partial=true --beam=$beam \
    ../model/model.mdl "gunzip -c tmp/HCLG_filler.fst.gz |" ark:tmp/feat.ark ark,t:tmp/free_phone \
    2> tmp/log_decode

  local like2=$(grep 'for utterance utt is' tmp/log_decode \
    | sed 's/.* is \([-.0-9]\+\) over.*$/\1/')

  local likeratio=$(perl -e "print(exp((${like1})-(${like2})));")

  echo $like1 $like2 $likeratio
}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
get_ratio $@
