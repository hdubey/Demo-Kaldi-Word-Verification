#!/usr/bin/env zsh
# vim: fdm=marker
# Shell Functions
#***************************************************************************
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
#***************************************************************************

# Get the current timestamp string
function getDateStamp { # {{{
  date +'%Y.%m.%d %H:%M:%S'
} # }}}

# Print a line of red error message and exit
function abort { # {{{
  local strInfo="$1"
  echo -e "\e[1;31m [E] $strInfo\e[m" >&2
  exit 2
} # }}}

# ========== Task Management ========== #

# Run background task
# This script assumes that DEMO_LOG is defined
# runbg task_title number command
function runBG { # {{{
  local strTitle="$1"
  local num=$2
  local cmd="$3"
  local thislog="${DEMO_LOG}_bg_${strTitle}.$num.log"
  echo -e "\n\n == (bg task) $strTitle $num ==\n$(getDateStamp)\n" >> "$thislog"
  echo " [I] Start BG Task $strTitle $num" >> "$DEMO_LOG"
  local DEMO_TIMESTAMP_BG=$SECONDS
  (
    # To prevent eval processes not get killed in cygwin
    if [[ $(uname -s) == CYGWIN* ]]; then
      trap "exit 1" SIGINT SIGSTOP SIGHUP SIGTERM SIGKILL
    fi

    eval "$cmd" >> "$thislog" 2>&1
    local rsltShell=$?
    local timeElapse=$(($SECONDS - $DEMO_TIMESTAMP_BG))
    if [[ $rsltShell == 0 ]]; then
      echo " [I] Background Task $strTitle $num Completed in ${timeElapse}s" >> $DEMO_LOG
    else
      abort "Task $strTitle $num Failed in ${timeElapse}s"
    fi
  ) &
} # }}}
