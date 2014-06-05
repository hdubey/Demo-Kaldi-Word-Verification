#!/usr/bin/env zsh
# vim: fdm=marker
# Record actual wave data and denoise
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

function record_data {
  mkdir -p tmp log

  sox -V1 -d -c 1 -r 16000 tmp/talk.wav trim 0 00:03 loudness 9
  sox tmp/talk.wav log/$1.wav noisered tmp/noise.prof 0.25 loudness 10 vad -T 0.2 reverse vad -T 0.2 reverse dither

  echo Wavefile saved as log/$1.wav
}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
record_data $1
