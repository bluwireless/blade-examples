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
<%namespace name="apb" file="apb_regmod.v"/>\

`include "timer_controller_reg_defs.vh"
`include "apb_defines_defs.vh"

<%apb:mod block="${block}" cfg_port="cfg">\

// -----------------------------------------------------------------------------
// Expose Register Values on Control Bus
// -----------------------------------------------------------------------------
assign ${ports.ctrl.start}    = m_timer_registers_control_0_start_write & m_timer_registers_control_0_start_aw;
assign ${ports.ctrl.stop}     = m_timer_registers_control_0_stop_write & m_timer_registers_control_0_stop_aw;
assign ${ports.ctrl.load_val} = m_timer_registers_load_0_value_write;
assign ${ports.ctrl.load_en}  = m_timer_registers_load_0_value_aw;

// -----------------------------------------------------------------------------
// Register State from Control Bus
// -----------------------------------------------------------------------------
always @(posedge ${clock} or posedge ${reset}) begin : p_timer_state
    if (${reset}) begin
        m_timer_registers_state_0_state_read   <= 2'd0;
        m_timer_registers_current_0_value_read <= 32'd0;
    end else begin
        m_timer_registers_state_0_state_read   <= ${ports.ctrl.state};
        m_timer_registers_current_0_value_read <= ${ports.ctrl.current};
    end
end

</%apb:mod>\
