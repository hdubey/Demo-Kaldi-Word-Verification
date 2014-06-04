#!/usr/bin/env zsh
# vim: fdm=marker
# Download the lexicon, a one-time configuration
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

function download_lexicon {
  if [[ -f ../model/lexicon ]]; then
    abort "CMUDict is already installed"
  fi

  mkdir -p tmp log
  rm -f tmp/cmudict_tmp
  wget https://svn.code.sf.net/p/cmusphinx/code/trunk/cmudict/cmudict.0.7a -O tmp/cmudict_tmp

  # Keep only first prounciation of each word
  ( grep -v '^;;;' tmp/cmudict_tmp | \
    grep -v '([12345])' | sed 's/\s\+/ /g'; \
    cat ../config/extra_dict; echo '<SIL> SIL'; echo '<UNK> NSN') > ../model/lexicon

  # Verify
  if [[ $(cat ../model/lexicon | wc -l) -le 10 ]]; then
    rm -f ../model/lexicon
    abort "Some bad things happened"
  fi

  rm -f tmp/cmudict_tmp
}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
download_lexicon






