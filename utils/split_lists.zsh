#!/usr/bin/env zsh
# vim: fdm=marker
# Split list according to number of lines
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

# Usage: split_lists.zsh nlist ndigit input output

local nlist=$1
local ndigit=$2
local fin=$3
local fout=$4

local nlinetr=$(cat "$fin" | wc -l)
local nlinepart=$(($nlinetr/$nlist+1))

split -d -a $ndigit -l $nlinepart \
  "$fin" "$fout"
return $?
