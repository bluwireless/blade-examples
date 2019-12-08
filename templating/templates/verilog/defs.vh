<%doc>
Copyright (C) 2019 Blu Wireless Ltd.
All Rights Reserved.

This file is part of BLADE.

BLADE is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

BLADE is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
BLADE.  If not, see <https://www.gnu.org/licenses/>.

--------------------------------------------------------------------------------

Template    :   defs.vh
Description :   Converts defined constants into `defines
</%doc>\
<%include file="copyright.txt" args="lc_param='//'"/>\
<%namespace name="filters" module="helpers.filters"/>\
<%
all_defs = {}
for define in defines:
    all_defs[filters.constStyle(define.id)] = (define.value, define.description)
max_id_len = max([len(x) for x in all_defs.keys()]) if len(all_defs.keys()) > 0 else 0
%>\
<%filters:tabify separators="/">
%for define in all_defs:
`define ${define} ${(max_id_len-len(define))*" "}${all_defs[define][0]} ${filters.optComment(all_defs[define][1])}
%endfor ## define in defines
</%filters:tabify>