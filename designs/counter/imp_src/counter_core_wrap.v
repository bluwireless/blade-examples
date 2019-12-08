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
// -----------------------------------------------------------------------------
// Assignments
// -----------------------------------------------------------------------------
wire [31:0] load_val = ${ports.clear.bit} ? 32'd0 : ${ports.ctrl.load_val};
wire        load_en  = ${ports.clear.bit} || ${ports.ctrl.load_en};

// -----------------------------------------------------------------------------
// Module instantiation of the counter logic
// -----------------------------------------------------------------------------
CounterCore core (
    .clk     (${clock}),
    .rst     (${reset}),
    .start   (${ports.ctrl.start}),
    .stop    (${ports.ctrl.stop}),
    .load_val(load_val),
    .load_en (load_en),
    .active  (${ports.ctrl.active}),
    .counter (${ports.ctrl.counter})
);

</%module:mod>\
