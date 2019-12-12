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

Template    :   counter_core.v
Description :   Templated implementation of the counter core
</%doc>\
<%include file="copyright.txt" args="lc_param='//'"/>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="blademod" module="helpers.mod_common"/>\
<%namespace name="module" file="module.v"/>\

<%module:mod block="${block}">\

reg        active;
reg        overflow;
reg [31:0] counter;

always @(posedge ${clock} or posedge ${reset}) begin
    if (${reset} == 1'b1) begin
        active   <= 1'b0;
        overflow <= 1'b0;
        counter  <= 32'd0;
    end else begin
        // Activate the counter when the start signal is strobed
        if (${ports.ctrl.start}) begin
            active <= 1'b1;
        // Halt the counter when the stop signal is strobed
        end else if (${ports.ctrl.stop}) begin
            active <= 1'b0;
        // When the load enable signal is strobed, adopt the load value
        end else if (${ports.ctrl.load_en}) begin
            counter <= ${ports.ctrl.load_val};
        // Otherwise, when active, just count normally
        end else if (active) begin
            counter <= (counter + 32'd1);
            if (counter == {32{1'b1}}) overflow <= 1'b1;
        end
    end
end

assign ${ports.ctrl.state}   = active ? (overflow ? 2'b11 : 2'b01) : 2'b00;
assign ${ports.ctrl.current} = counter;

</%module:mod>\
