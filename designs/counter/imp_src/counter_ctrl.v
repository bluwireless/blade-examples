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

Template    :   counter_ctrl.v
Description :   Templated implementation of the counter control block
</%doc>\
<%include file="copyright.txt" args="lc_param='//'"/>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="blademod" module="helpers.mod_common"/>\
<%namespace name="axi4lite" file="axi4lite_regmod.v"/>\

`include "axi4_defines_defs.vh"
`include "counter_ctrl_reg_defs.vh"

<%axi4lite:mod block="${block}" cfg_port="cfg">\

// -----------------------------------------------------------------------------
// Expose Register Values on Control Bus
// -----------------------------------------------------------------------------
%for i in range(8):
assign ${ports.ctrl[i].start}    = m_ctrl_${i}_ctrl_${i}_control_0_start_write & m_ctrl_${i}_ctrl_${i}_control_0_start_aw;
assign ${ports.ctrl[i].stop}     = m_ctrl_${i}_ctrl_${i}_control_0_stop_write & m_ctrl_${i}_ctrl_${i}_control_0_stop_aw;
assign ${ports.ctrl[i].load_val} = m_ctrl_${i}_ctrl_${i}_load_0_value_write;
assign ${ports.ctrl[i].load_en}  = m_ctrl_${i}_ctrl_${i}_load_0_value_aw;
%endfor ## i in range(8)

// -----------------------------------------------------------------------------
// Register State from Control Bus
// -----------------------------------------------------------------------------
always @(posedge ${clock} or posedge ${reset}) begin : p_timer_state
    if (${reset}) begin
%for i in range(8):
        m_ctrl_${i}_ctrl_${i}_status_0_state_read  <= 1'd0;
        m_ctrl_${i}_ctrl_${i}_current_0_value_read <= 32'd0;
%endfor ## i in range(8):
    end else begin
%for i in range(8):
        m_ctrl_${i}_ctrl_${i}_status_0_state_read  <= ${ports.ctrl[i].active};
        m_ctrl_${i}_ctrl_${i}_current_0_value_read <= ${ports.ctrl[i].counter};
%endfor ## i in range(8):
    end
end

</%axi4lite:mod>\
