#!/usr/bin/env zsh
# vim: fdm=marker
# Path and settings
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

# Make the shell scripts less error-prone
emulate -L zsh
setopt bsdecho
setopt multios
setopt nobanghist
setopt nounset
setopt nobgnice

if [[ x${DEMO_ROOT:-unset} == xunset ]]; then
  typeset -rx DEMO_ROOT="${0:a:h}"
  typeset -x LC_ALL='C'
  typeset -x OPENBLAS_NUM_THREADS=1
  typeset -x OMP_NUM_THREADS=1

  source "$DEMO_ROOT/local.zsh" || exit 1

  PATH="$KALDI_ROOT/src/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/kwsbin:$PATH"
  PATH="$KALDI_ROOT/egs/wsj/s5/utils:$KALDI_ROOT/tools/openfst/bin:$PATH"
  PATH="$DEMO_ROOT/utils:$PATH"

  # These are not designed to be modified, don't touch them!
  # Basically the default parallel settings
  typeset -rx DEMO_NPARF=5
  typeset -rx DEMO_NPARDIGIT=3
  typeset -rx DEMO_FORPARF="$(printf "%0${DEMO_NPARDIGIT}d\n" $(seq 0 $(($DEMO_NPARF-1))))"
  typeset -rx DEMO_FORPARV="$(printf "%0${DEMO_NPARDIGIT}d\n" $(seq 0 $(($DEMO_NPARV-1))))"
fi

source "$DEMO_ROOT/shellfunctions.zsh"

# Only do these if not sourced from interactive shell
if [[ $- != *i* ]] ; then
  trap 'abort "Signal: Killed by SIGINT or SIGQUIT" true' SIGINT SIGQUIT
  trap 'abort "Signal: Killed by SIGHUP" true' SIGHUP
  trap 'abort "Signal: Killed by SIGTERM" true' SIGTERM
  trap 'abort "Signal: Killed by SIGKILL" true' SIGKILL
  trap 'abort "Signal: Something wrong in pipes" true' SIGPIPE
  trap 'abort "Signal: Something aborted" true' SIGABRT
fi
