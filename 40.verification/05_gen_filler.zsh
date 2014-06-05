#!/usr/bin/env zsh
# vim: fdm=marker
# Generate filler graph
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

function gen_graph_filler {
  mkdir -p log tmp
  local DEMO_LOG=log/gen_graph.log

  local lastphone=$(tail -n 1 ../model/map_phone | cut -d' ' -f2)
  ( cat ../model/map_phone\
    ; echo "#0 $(($lastphone+1))" ) > tmp/map_phone_filler
  local nphone=$(cat tmp/map_phone_filler | wc -l)

  grep -v '^\(<eps>\|#\|SIL\|NSN\)' tmp/map_phone_filler \
    | sed 's/^\([^ ]\+\) .*/\1 \1/' > tmp/lexthis

  ( echo "<eps>" \
    ; cut -d ' ' -f 1 tmp/lexthis \
    | sort -u; echo "#0" \
    ) > tmp/list_word
  local nword=$(cat tmp/list_word | wc -l)
  seq 0 $(($nword-1)) \
    | paste -d ' ' tmp/list_word - > tmp/map_word_filler

  make_lexicon_fst.pl tmp/lexthis 0.5 SIL | \
    fstcompile --isymbols=tmp/map_phone_filler --osymbols=tmp/map_word_filler \
    --keep_isymbols=false --keep_osymbols=false | \
    fstaddselfloops "grep \#0 tmp/map_phone_filler | cut -d' ' -f2 |" \
    "grep \#0 tmp/map_word_filler | cut -d' ' -f2 |" | \
    fstarcsort --sort_type=olabel | gzip -c > tmp/L.fst.gz

  # Construct grammar
  nword=$(cat tmp/lexthis | wc -l)
  rm -f tmp/grammar
  weight_word=$(perl -e "print(-log(1.0/$nword));")
  cut -d' ' -f1 tmp/lexthis | sort -u | \
    sed "s/.*/0 0 & & $weight_word/" > tmp/grammar
  echo "0 0" >> tmp/grammar

  # Construct grammar graphs
  fstcompile --isymbols=tmp/map_word_filler --osymbols=tmp/map_word_filler \
    --keep_isymbols=false --keep_osymbols=false tmp/grammar | \
    gzip -c > tmp/G.fst.gz

  # Construct HCLG
  fsttablecompose "gunzip -c tmp/L.fst.gz |" \
    "gunzip -c tmp/G.fst.gz |" | \
    fstdeterminizestar --use-log=true | \
    fstminimizeencoded | gzip -c > tmp/LG.fst.gz

  gunzip -c tmp/LG.fst.gz | \
    fstcomposecontext --context-size=3 --central-position=1 \
    tmp/ilabels | gzip -c > tmp/CLG.fst.gz

  make-h-transducer --disambig-syms-out=tmp/tid_dis.int \
    tmp/ilabels ../model/tree ../model/model.mdl | \
    fsttablecompose - "gunzip -c tmp/CLG.fst.gz |" | \
    fstdeterminizestar --use-log=true | \
    fstrmsymbols tmp/tid_dis.int | \
    fstrmepslocal | fstminimizeencoded | \
    add-self-loops --self-loop-scale=0.1 --reorder=true ../model/model.mdl | \
    gzip -c > tmp/HCLG_filler.fst.gz \
}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
gen_graph_filler
