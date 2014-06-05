#!/usr/bin/env zsh
# vim: fdm=marker
# Generate graph
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

function batch_verification {
  mkdir -p log tmp
  local DEMO_LOG=log/batch_verification.log
  local ascale=0.15
  local beam=40

  if [[ ! -f tmp/HCLG_filler.tar.gz ]]; then
    ./05_gen_filler.zsh 2>> $DEMO_LOG
  fi

  ls data/ \
    | grep '.*_[0-9]\.wav' \
    | sed 's/_.*$//' \
    | sort -u > tmp/list_batch_verification

  for thisset in $(cat tmp/list_batch_verification); do

    ./10_gen_graph.zsh $thisset 2>> $DEMO_LOG

    for (( i = 0; i <= 3; i++ )); do
      local thisfile=data/${thisset}_$i.wav
      if [[ ! -f $thisfile ]]; then
        continue
      fi
      echo utt $thisfile > tmp/testwav.scp

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
        ../model/model.mdl "gunzip -c tmp/HCLG_filler.fst.gz |" ark:tmp/feat.ark ark,t:- \
        > /dev/null 2> tmp/log_decode

      local like2=$(grep 'for utterance utt is' tmp/log_decode \
        | sed 's/.* is \([-.0-9]\+\) over.*$/\1/')

      printf "\e[1;33m${thisset}_$i\e[m: ($like1) over ($like2), ratio: \e[1;35m"
      perl -e "print(exp((${like1})-(${like2})));"
      echo -e "\e[m"
    done # end each subset
  done # end each set


}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
batch_verification
