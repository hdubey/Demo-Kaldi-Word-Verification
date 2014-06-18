#!/usr/bin/env zsh
# vim: fdm=marker
# Delete things that should be auto-generated
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

function clean_up {
  cd ..
  rm -rfv 10.prepare/{tmp,log}
  rm -rfv 20.train/{tmp,log}
  rm -rfv 30.record/{tmp,log}
  rm -rfv 40.verification/{tmp,log}
}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}"
clean_up

