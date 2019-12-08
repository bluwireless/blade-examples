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

Template    :   mod_wiring.v
Description :   Provides a straight-to-RTL implementation of the interconnectivity
                of a block, assuming that all modules use component-by-component
                wiring style.
</%doc>\
<%include file="copyright.txt" args="lc_param='//'"/>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="mod" module="helpers.mod_common"/>\
<%namespace name="module" file="module.v"/>\

<%module:mod block="${block}">
## No custom implementation required, all built into default template
</%module:mod>
