#!/usr/bin/env zsh
# vim: fdm=marker
# Train normal phone model
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

# Sub-routine to align training label
# USAGE: $0 model_name beam_size [ali_name=ali]
function AlignLabel { # {{{
  gmm-boost-silence --boost=$boost 1 tmp/model_$1.mdl tmp/tmp_forali.mdl \
    2>> $DEMO_LOG || exit 1
  local beam=$2
  local aliname=ali
  if [[ x${3+set} == xset ]]; then # if defined
    local aliname=$3
  fi
  local title=$(echo $1 | sed 's/^[a-z]/\u&/')
  for z in ${(f)DEMO_FORPARF}; do # {{{
    runBG "Align$title" $z "${feats/@@/$z} | \
      gmm-align-compiled $optScale --beam=$beam --retry-beam=$(($beam*5)) \
      'tmp/tmp_forali.mdl' 'ark:gunzip -c tmp/fsts.part$z.gz|' \
      ark,o,s,cs:- ark:tmp/$aliname.part$z"
  done; wait # }}}
  rm -f tmp/tmp_forali.mdl
} # }}}

# 1 iteration of training GMMs
# USAGE: $0 model_name model_out [mix_target mix_power]
function GMMReEst { # {{{
  local title=$(echo $1 | sed 's/^[a-z]/\u&/')
  for z in ${(f)DEMO_FORPARF}; do # {{{
    runBG "Accum$title" $z "${feats/@@/$z} | \
      gmm-acc-stats-ali --binary=true tmp/model_$1.mdl \
      ark,o,s,cs:- ark,o,s,cs:tmp/ali.part$z tmp/acc.part$z"
  done; wait # }}}
  if [[ x${3+set} == xset ]]; then # if defined
    gmm-est --min-gaussian-occupancy=3 --mix-up=$3 --power=$4 \
      tmp/model_$1.mdl "gmm-sum-accs - tmp/acc.part*|" \
      tmp/model_$2.mdl 2>> $DEMO_LOG || exit 1
  else
    gmm-est --min-gaussian-occupancy=3 \
      tmp/model_$1.mdl "gmm-sum-accs - tmp/acc.part*|" \
      tmp/model_$2.mdl 2>> $DEMO_LOG || exit 1
  fi
} # }}}

function phone_model {
  mkdir -p log tmp
  local DEMO_LOG=log/phone_model.log
  local feats="add-deltas \
    --delta-order=2 --delta-window=2 \
    ark,o,s,cs:tmp/train.ark.part@@ ark:-"
  local optScale="--transition-scale=1.0 --acoustic-scale=0.05 --self-loop-scale=0.1"
  local boost=1.2

  (echo; echo "TRAIN PHONE MODEL $(getDateStamp)"; echo) >> $DEMO_LOG

  echo "[1;33mPREPARING FILES ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{

  cut -d ' ' -f 2- ../model/lexicon | tr ' ' '\n' | sort -u | \
    grep -v '\<SIL\>\|\<NSN\>' | grep -v '^$' > tmp/list_nonsil
  ( echo 'SIL'; echo 'NSN' ) > tmp/list_sil
  ( echo "<eps>"; cat tmp/list_sil; cat tmp/list_nonsil; \
    ) > tmp/list_phone
  ( echo "<eps>"; cut -d' ' -f1 ../model/lexicon) > tmp/list_word

  # Construct mappings of words and phones
  local nphone=$(cat tmp/list_phone | wc -l)
  local nword=$(cat tmp/list_word | wc -l)
  seq 0 $(($nphone-1)) \
    | paste -d ' ' tmp/list_phone - > tmp/map_phone
  seq 0 $(($nword-1)) \
    | paste -d ' ' tmp/list_word - > tmp/map_word

  # Generating training labels
  cat $CORPUS_WSJ0/**/*.dot \
    | wsj_pick_transcription.pl ../config/aurora4_multi.scp \
    | normalize_transcript_wsj.pl '<UNK>' > tmp/labeltext
  sym2int.pl --map-oov '<UNK>' -f 2- tmp/map_word tmp/labeltext \
    > tmp/tmp_label || exit 1
  split_lists.zsh $DEMO_NPARF $DEMO_NPARDIGIT \
    tmp/tmp_label tmp/label.ark.part || exit 1
  rm -f tmp/tmp_label

  # Construct lexicon graphs
  ( make_lexicon_fst.pl ../model/lexicon 0.5 SIL \
    | fstcompile --isymbols=tmp/map_phone --osymbols=tmp/map_word \
    --keep_isymbols=false --keep_osymbols=false \
    | fstarcsort --sort_type=olabel | gzip -c ) > tmp/L.fst.gz \
    2>> $DEMO_LOG || exit 1

  # Splitting features
  copy-feats ark,o,s,cs:"gunzip -c feat/cmvn.ark.gz |" \
    ark,scp:tmp/tmp_ark,tmp/tmp_flist \
    2>> $DEMO_LOG || exit 1
  split_lists.zsh $DEMO_NPARF $DEMO_NPARDIGIT \
    tmp/tmp_flist tmp/train.scp.part || exit 1
  for z in ${(f)DEMO_FORPARF}; do # {{{
    copy-feats scp,o,s,cs:tmp/train.scp.part$z \
      ark:tmp/train.ark.part$z \
      2>> $DEMO_LOG || exit 1
  done; wait # }}}
  rm -f tmp/tmp_ark tmp/train.scp.part*

  # }}}

  echo "[1;33mINITIALIZE MODEL ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{

  # Construct topology of model, filtering out disambig symbols
  local listNonsil="$(grep -v '\<SIL\>\|\<eps\>\|\<NSN\>' \
    tmp/map_phone | grep -v '^#' | cut -d ' ' -f 2- | tr '\n' ':')"
  local listSil="$(grep '\<SIL\>\|\<NSN\>' tmp/map_phone | \
    cut -d ' ' -f 2- | tr '\n' ':')"
  gen_topo.pl 3 5 $listNonsil $listSil > tmp/topo

  # Initialize GMMs
  gmm-init-mono --train-feats="ark,o,s,cs:${feats/@@/000} |" \
    tmp/topo $(feat-to-dim "ark,o,s,cs:${feats/@@/000} |" - 2>/dev/null) \
    tmp/model_init.mdl tmp/treemono 2>> $DEMO_LOG || exit 1
  for z in ${(f)DEMO_FORPARF}; do # {{{
    runBG "CompileGraph0" $z "gunzip -c tmp/L.fst.gz \
      | compile-train-graphs tmp/treemono tmp/model_init.mdl \
      - ark:tmp/label.ark.part$z ark:- \
      | gzip -c > tmp/fsts.part$z.gz"
  done; wait # }}}

  # The first pass: equally-spaced
  for z in ${(f)DEMO_FORPARF}; do # {{{
    runBG "Align0" $z "${feats/@@/$z} | \
      align-equal-compiled 'ark:gunzip -c tmp/fsts.part$z.gz|' \
      ark,o,s,cs:- ark:tmp/ali.part$z"
  done; wait # }}}
  GMMReEst init mono1 || exit 1

  # Initial training: make the initial model better
  for (( i = 0; i < 4; i++ )); do
    printf "\e[1;34mInitial: iteration $i ...\e[m\n"
    AlignLabel mono1 7 || exit 1
    GMMReEst mono1 mono1 || exit 1
  done

  # }}}

  local nIterMonoInc=30 # iters to increase number of mixtures
  local nIterMonoFinal=10
  local nMixMonoTarget=1000   # Target number of mixtures
  local nMixMono=$(gmm-info tmp/model_mono1.mdl 2>/dev/null | grep gaussian | cut -d ' ' -f 4)
  local nMixMonoInc=$((($nMixMonoTarget-$nMixMono)/$nIterMonoInc))

  echo "[1;33mMONOPHONE MIXUP ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{
    install tmp/model_mono1.mdl tmp/model_mono2.mdl || exit 1

    # Do mix-up training
    for (( i = 0; i < $nIterMonoInc; i++ )); do
      printf "\e[1;34mMono up: iteration $i ...\e[m\n"

      if [[ $i < 10 || $(($i%2)) == 0 ]]; then
        AlignLabel mono2 10 || exit 1
      fi
      GMMReEst mono2 mono2 $nMixMono 0.25 || exit 1
      nMixMono=$(($nMixMono + $nMixMonoInc))
    done
  # }}}

  echo "[1;33mMONOPHONE FINAL ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{
    install tmp/model_mono2.mdl tmp/model_mono3.mdl || exit 1

    # Targeting the final model
    for (( i = 0; i < $nIterMonoFinal; i++ )); do
      printf "\e[1;34mMono final: iteration $i ...\e[m\n"

      if [[ $i < 3 || $(($i%2)) == 0 ]]; then
        AlignLabel mono3 10 || exit 1
      fi
      GMMReEst mono3 mono3 $nMixMonoTarget 0.2 || exit 1
    done
    install tmp/model_mono3.mdl tmp/model_mono.mdl

    # Do final alignment
    AlignLabel mono 12 ali_mono || exit 1
  # }}}

  local nIterTriInc=30 # iters to increase number of mixtures
  local nIterTriFinal=12
  local nMixTri=3000
  local nMixTriTarget=23000   # Target number of mixtures
  local nMixTriInc=$((($nMixTriTarget-$nMixTri)/$nIterTriInc))

  echo "[1;33mSPLITTING CONTEXT ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{
    local lPhoneCI=$(cat tmp/list_sil | sym2int.pl tmp/map_phone | \
      tr '\n' ':' | sed 's/:$//')
    for z in ${(f)DEMO_FORPARF}; do # {{{
      runBG "AccTreeStats" $z "${feats/@@/$z} | \
        acc-tree-stats --ci-phones='$lPhoneCI' \
        tmp/model_mono.mdl ark,o,s,cs:- \
        ark:tmp/ali_mono.part$z tmp/acctree.part$z"
    done; wait # }}}
    sum-tree-stats tmp/acctree tmp/acctree.part* \
      2>> $DEMO_LOG || exit 1

    # Building questions based on clustering
    grep -v '^#\|<eps>' tmp/list_phone | \
      sym2int.pl tmp/map_phone > tmp/list_realphone.int
    cluster-phones tmp/acctree tmp/list_realphone.int tmp/list_quest.int \
      2>> $DEMO_LOG || exit 1
    # Additional questions: phone type, silence and stress
    (echo "SIL NSN"; \
      echo "CH JH"; \
      echo "DH F S SH TH V Z ZH"; \
      echo "L R"; \
      echo "M N NG"; \
      echo "W Y"; \
      echo "B D G K P T"; \
      echo "B CH D DH F G HH JH K L M N NG P R S SH T TH V W Y Z ZH"; \
      echo "AA0 AE0 AH0 AO0 AW0 AY0 EH0 ER0 EY0 IH0 IY0 OW0 OY0 UH0 UW0"; \
      echo "AA1 AE1 AH1 AO1 AW1 AY1 EH1 ER1 EY1 IH1 IY1 OW1 OY1 UH1 UW1"; \
      echo "AA2 AE2 AH2 AO2 AW2 AY2 EH2 ER2 EY2 IH2 IY2 OW2 OY2 UH2 UW2"; \
      echo "AA0 AE0 AH0 AO0 AW0 AY0"; \
      echo "EH0 ER0 EY0"; \
      echo "IH0 IY0"; \
      echo "OW0 OY0"; \
      echo "UH0 UW0"; \
      echo "AA1 AE1 AH1 AO1 AW1 AY1"; \
      echo "EH1 ER1 EY1"; \
      echo "IH1 IY1"; \
      echo "OW1 OY1"; \
      echo "UH1 UW1"; \
      echo "AA2 AE2 AH2 AO2 AW2 AY2"; \
      echo "EH2 ER2 EY2"; \
      echo "IH2 IY2"; \
      echo "OW2 OY2"; \
      echo "UH2 UW2"; \
      echo "AA0 AA1 AA2 AE0 AE1 AE2 AH0 AH1 AH2 AO0 AO1 AO2 AW0 AW1 AW2 AY0 AY1 AY2"; \
      echo "EH0 EH1 EH2 ER0 ER1 ER2 EY0 EY1 EY2"; \
      echo "IH0 IH1 IH2 IY0 IY1 IY2"; \
      echo "OW0 OW1 OW2 OY0 OY1 OY2"; \
      echo "UH0 UH1 UH2 UW0 UW1 UW2"; \
      echo "AA0 AA1 AA2 AE0 AE1 AE2 AH0 AH1 AH2 AO0 AO1 AO2 AW0 AW1 AW2 AY0 AY1 AY2 EH0 EH1 EH2 ER0 ER1 ER2 EY0 EY1 EY2 IH0 IH1 IH2 IY0 IY1 IY2 OW0 OW1 OW2 OY0 OY1 OY2 UH0 UH1 UH2 UW0 UW1 UW2") | \
      sym2int.pl tmp/map_phone >> tmp/list_quest.int
    compile-questions tmp/topo tmp/list_quest.int tmp/quest \
      2>> $DEMO_LOG || exit 1
    cat ../config/aurora4_roots | sym2int.pl -f 3- tmp/map_phone > tmp/roots.int

    # Construct tree and new triphone model
    build-tree --max-leaves=$nMixTri tmp/acctree tmp/roots.int \
      tmp/quest tmp/topo tmp/treetri \
      2>> $DEMO_LOG || exit 1
    gmm-init-model --write-occs=tmp/occstri  \
      tmp/treetri tmp/acctree tmp/topo tmp/model_triinit.mdl \
      2>> $DEMO_LOG || exit 1
    gmm-mixup --mix-up=$nMixTri tmp/model_triinit.mdl tmp/occstri \
      tmp/model_triinit.mdl \
      2>> $DEMO_LOG || exit 1

    # Construct Train graph
    rm -f tmp/fsts.part*.gz
    for z in ${(f)DEMO_FORPARF}; do # {{{
      runBG "CompileGraphTri" $z "gunzip -c tmp/L.fst.gz | \
        compile-train-graphs tmp/treetri tmp/model_triinit.mdl \
        - ark:tmp/label.ark.part$z ark:- | \
        gzip -c > tmp/fsts.part$z.gz"
    done; wait # }}}
  # }}}

  echo "[1;33mTRIPHONE MIXUP ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{
    install tmp/model_triinit.mdl tmp/model_tri2.mdl || exit 1

    # Make alignment for current model
    for z in ${(f)DEMO_FORPARF}; do # {{{
      convert-ali tmp/model_mono.mdl tmp/model_triinit.mdl tmp/treetri \
        ark:tmp/ali_mono.part$z ark:tmp/ali.part$z \
        2>> $DEMO_LOG || exit 1
    done; wait # }}}

    # Do mix-up training
    for (( i = 0; i < $nIterTriInc; i++ )); do
      printf "\e[1;34mTri up: iteration $i ...\e[m\n"

      if [[ $i < 4 || $(($i%2)) == 1 ]]; then
        AlignLabel tri2 10 || exit 1
      fi
      GMMReEst tri2 tri2 $nMixTri 0.25 || exit 1
      nMixTri=$(($nMixTri + $nMixTriInc))
    done
  # }}}

  echo "[1;33mTRIPHONE FINAL ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{
    install tmp/model_tri2.mdl tmp/model_tri3.mdl || exit 1

    # Targeting the final model
    for (( i = 0; i < $nIterTriFinal; i++ )); do
      printf "\e[1;34mTri final: iteration $i ...\e[m\n"

      if [[ $(($i%3)) == 2 ]]; then
        AlignLabel tri3 10 || exit 1
      fi
      GMMReEst tri3 tri3 $nMixTriTarget 0.2 || exit 1
    done
    install tmp/model_tri3.mdl tmp/model_tri.mdl
  # }}}

  echo "[1;33mFINAL ($(getDateStamp))[m" | tee -a $DEMO_LOG # {{{
    install tmp/model_tri.mdl ../model/model.mdl
    install tmp/treetri ../model/tree
    install tmp/list_sil ../model/
    install tmp/list_nonsil ../model/
    install tmp/map_phone ../model/
    rm -f tmp/acc* tmp/ali* tmp/fst* tmp/train*
  # }}}

}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
phone_model
