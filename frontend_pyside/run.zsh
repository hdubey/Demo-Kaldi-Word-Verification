#!/usr/bin/env zsh
# vim: fdm=marker
# Run PySide GUI runner
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

function run_gui {
  local gui_id=$1

  if [[ $(uname -s) == CYGWIN* ]]; then
    $PYTHON_EXECUTABLE "$(cygpath -m "$SOURCEDIR/gui${gui_id}.py")"
  else
    $PYTHON_EXECUTABLE "$SOURCEDIR/gui${gui_id}.py"
  fi
}

typeset -rx SOURCEDIR="${0:a:h}"
source "${SOURCEDIR}/../env.zsh"
cd "${SOURCEDIR}/.."
run_gui $@
