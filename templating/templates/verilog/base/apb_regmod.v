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

Template    :   verilog_axi4.v
Description :   Base modules for AXI4 register blocks
</%doc>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="blademod" module="helpers.mod_common"/>\
<%namespace name="regmod" file="regmod.v"/>\

`include "axi4_defines_defs.vh"

<%def name="mod(block, cfg_port)">\
<%regmod:mod block="${block}">\
// =============================================================================
// APB Register Decode
// =============================================================================
<% apb = ports[cfg_port] %>\
reg [`APB_PDATA_WIDTH-1:0] ${apb.prdata};
reg                        ${apb.pslverr};

// Tie PREADY high, we can always accept transactions
assign ${apb.pready} = 1'b1;

always @(posedge ${clock} or posedge ${reset}) begin : apb_decode
    reg [`APB_PDATA_WIDTH-1:0] curr_read;
    reg [1:0]                  curr_error;
    if (${reset} == 1'b1) begin
        $display($time, ": Decoder in reset");
        // Reset the registers
        register_reset();

        // Initialise the APB port response
        ${apb.prdata}  <= 32'd0;
        ${apb.pslverr} <= 1'd0;
    end else begin

        // Clear read and write strobes
        clear_bus_strobes();

        // Process transaction in the first cycle when PSEL high but PENABLE low
        if (${apb.psel} && !${apb.penable}) begin
            if (${apb.pwrite} && ${apb.pstrb} == {`APB_PSTRB_WIDTH{1'b1}}) begin
                curr_error = register_write(${apb.paddr}, ${apb.pwdata});
            end else if (${apb.pwrite} && ${apb.pstrb} == `APB_PSTRB_WIDTH'd0) begin
                // Ignore empty writes
                curr_error = `REG_ACCESS_OK;
            end else if (${apb.pwrite}) begin
                // If this clause is hit, then the strobe is not all 0s or all 1s
                $display($time, ": ERROR: Register block does not accept partial writes");
                curr_error = `REG_ACCESS_DECERR;
            end else begin
                {curr_read, curr_error} = register_read(${apb.paddr});
                ${apb.prdata} <= curr_read;
            end
            // If MSB is set in the error response, raise PSLVERR
            ${apb.pslverr} <= curr_error[1];
        // If no transaction occurred, clear the slave error
        end else begin
            ${apb.pslverr} <= 1'b0;
        end

    end
end

## Implementation
${caller.body()}
</%regmod:mod>\
</%def>\
