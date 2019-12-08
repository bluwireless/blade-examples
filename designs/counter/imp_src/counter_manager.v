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

Template    :   counter_manager.v
Description :   Templated implementation of the counter manager
</%doc>\
<%include file="copyright.txt" args="lc_param='//'"/>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="blademod" module="helpers.mod_common"/>\
<%namespace name="module" file="module.v"/>\

<%module:mod block="${block}">\
reg [7:0] clear_signals;

%for i in range(8):
assign ${ports.reset_timer[i].bit} = clear_signals[${i}];
%endfor ## i in range(8)

always @(posedge ${clock} or posedge ${reset}) begin
    if (${reset} == 1'b1) begin
        clear_signals <= 8'd0;
    end else begin
        clear_signals <= {8{${ports.clear_all.bit}}};
    end
end

</%module:mod>\
