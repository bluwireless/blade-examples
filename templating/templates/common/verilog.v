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

Template    :   verilog.v
Description :   Common functions for generating Verilog.
</%doc>\

<%def name="make_range(width_or_msb, lsb=None)">\
%if lsb != None:
    %if width_or_msb != lsb:
[${width_or_msb}:${lsb}]\
    %else:
[${lsb}]\
    %endif
%elif width_or_msb > 1:
[${width_or_msb-1}:0]\
%endif
</%def>