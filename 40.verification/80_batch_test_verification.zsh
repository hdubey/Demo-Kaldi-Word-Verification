#!/usr/bin/env zsh
# vim: fdm=marker
# Run batch test on the verification task
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
      local rtn="$(./20_get_ratio.zsh "$thisset" "$thisfile")"
      local like1=$(echo $rtn | cut -d' ' -f1)
      local like2=$(echo $rtn | cut -d' ' -f2)
      local likeratio=$(echo $rtn | cut -d' ' -f3)

      printf "\e[1;33m${thisset}_$i\e[m: ($like1) over ($like2), ratio: \e[1;35m$likeratio\e[m\n"
    done # end each subset
  done # end each set


}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
batch_verification
