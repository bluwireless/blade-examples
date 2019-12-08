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

Template    :   regmod.v
Description :   Generate module with registers and breakout wiring. Creates two
                'register_write' and 'register_read' functions which need to be
                driven by a bus decoder implementation.
</%doc>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="blademod" module="helpers.mod_common"/>\
<%namespace name="bladereg" module="helpers.reg_common"/>\
<%namespace name="module" file="module.v"/>\
<%namespace name="verilog" file="verilog.v"/>\

## =============================================================================
## regmod:mod - Extends module:mod and adds a function driven register interface
##              which can be driven by a protocol implementation
## =============================================================================
<%def name="mod(block)">\
<%module:mod block="${block}">\
<%
from math import ceil, log2
context.fields        = {}
context.max_reg_width = 0
context.max_reg_addr  = 0
%>\
// =============================================================================
// Block Registers
// =============================================================================
<%filters:tabify separators="m">\
%for group in block.registers:
    %for reg in group.registers:
<%
        if reg.width > context.max_reg_width:
            context.max_reg_width = reg.width
        if reg.getOffset() > context.max_reg_addr:
            context.max_reg_addr = reg.getOffset()
%>\
        %for field in reg.fields:
<%          context.fields[field] = bladereg.register_field_name(group, reg, field) %>\
            %if bladereg.is_bus_writeable(reg):
${"wire" if bladereg.is_active_write(reg) else "reg"} ${verilog.make_range(field.size)} ${context.fields[field]}_write;
            %endif ## bladereg.is_bus_writeable(reg)
            %if bladereg.is_block_writeable(reg):
reg ${verilog.make_range(field.size)} ${context.fields[field]}_read;
            %endif ## bladereg.is_block_writeable(reg)
            %if bladereg.is_active_write(reg):
reg ${context.fields[field]}_aw;
            %endif ## bladereg.is_active_write(reg)
            %if bladereg.is_active_read(reg):
reg ${context.fields[field]}_ar;
            %endif ## bladereg.is_active_read(reg)
        %endfor ## field in reg.fields
    %endfor ## reg in group.registers
%endfor ## group in block.registers
</%filters:tabify>\

// Storage of the last written value (used for combinatorial decode)
reg ${verilog.make_range(context.max_reg_width)} reg_write_data;

// =============================================================================
// Combinatorial value decode for active-write registers
// =============================================================================
<%filters:tabify separators="=">\
%for group in block.registers:
    %for reg in group.registers:
        %if bladereg.is_active_write(reg):
            %for field in reg.fields:
<%          prefix = filters.constStyle(group.id + "_" + reg.id + "_" + field.id) %>\
                %if field.size == 1:
assign ${bladereg.register_field_name(group, reg, field)}_write = reg_write_data[`${prefix}_LSB];
                %else:
assign ${bladereg.register_field_name(group, reg, field)}_write = reg_write_data[`${prefix}_MSB:`${prefix}_LSB];
                %endif ## field.size == 1
            %endfor ## field in reg.fields
        %endif ## bladereg.is_active_write(reg)
    %endfor ## reg in group.registers
%endfor ## group in block.registers
</%filters:tabify>\

// =============================================================================
// clear_bus_strobes: Function to clear read and write strobes
// =============================================================================
task clear_bus_strobes;
    begin
%for group in block.registers:
    %for reg in group.registers:
        %for field in reg.fields:
            %if bladereg.is_active_write(reg):
        ${bladereg.register_field_name(group, reg, field)}_aw = 1'b0;
            %endif ## bladereg.is_active_write(reg)
            %if bladereg.is_active_read(reg):
        ${bladereg.register_field_name(group, reg, field)}_ar = 1'b0;
            %endif ## bladereg.is_active_read(reg)
        %endfor ## field in reg.fields
    %endfor ## reg in group.registers
%endfor ## group in block.registers
    end
endtask

// =============================================================================
// register_reset: Reset For Bus-Writeable Registers
// =============================================================================
task register_reset;
    begin
        reg_write_data = ${context.max_reg_width}'h0;
%for group in block.registers:
    %for reg in group.registers:
        %for field in reg.fields:
            %if bladereg.is_bus_writeable(reg) and not bladereg.is_active_write(reg):
        ${context.fields[field]}_write = `${group.id + "_" + reg.id + "_" + field.id | filters.constStyle}_RESET;
            %endif
        %endfor ## field in reg.fields
    %endfor ## reg in group.registers
%endfor ## group in block.registers
        // Reset bus strobes
        clear_bus_strobes();
    end
endtask

// =============================================================================
// Register access response types
// =============================================================================
`define REG_ACCESS_OK     2'b00 // All ok - no problems
`define REG_ACCESS_UNUSED 2'b01 // Unused by implementation
`define REG_ACCESS_SLVERR 2'b10 // Bad access - write to read-only, or read from write-only
`define REG_ACCESS_DECERR 2'b11 // Invalid access - register out of range

// =============================================================================
// register_write: Write to all the fields of a register
// =============================================================================
<% reg_addr_size = int(ceil(log2(context.max_reg_addr))) if context.max_reg_addr > 0 else 0 %>\
function [1:0] register_write;
    input ${verilog.make_range(reg_addr_size)} address;
    input ${verilog.make_range(context.max_reg_width)} data;
    begin
        // Capture the latest write data
        reg_write_data = data;
        // Initialise return value to 0 (success)
        register_write = `REG_ACCESS_OK;
        case (address)
%for group in block.registers:
    %for reg in group.registers:
            // ${group.id}.${reg.id}
            ${reg_addr_size}'h${"%x" % reg.getOffset()}: begin
        %if bladereg.is_bus_writeable(reg):
            %for field in reg.fields:
<%              prefix = filters.constStyle(group.id + "_" + reg.id + "_" + field.id) %>\
                %if bladereg.is_active_write(reg):
                ${bladereg.register_field_name(group, reg, field)}_aw = 1'b1;
                %elif field.size == 1:
                ${bladereg.register_field_name(group, reg, field)}_write = data[`${prefix}_LSB];
                %else:
                ${bladereg.register_field_name(group, reg, field)}_write = data[`${prefix}_MSB:`${prefix}_LSB];
                %endif ## bladereg.is_active_write(reg)
            %endfor ## field in reg.fields:
        %else:
                $display("WARNING: Wrote to read-only register ${group.id}.${reg.id}");
                register_write = `REG_ACCESS_SLVERR;
        %endif ## bladereg.is_bus_writeable(reg)
            end
    %endfor ## reg in group.registers
%endfor ## group in block.registers
            // Catch writes to invalid register addresses
            default: begin
                $display("WARNING: Writing to unknown register");
                register_write = `REG_ACCESS_DECERR;
            end
        endcase
    end
endfunction

// =============================================================================
// register_read: Read from all the fields in a register
// =============================================================================
function ${verilog.make_range(context.max_reg_width+2)} register_read;
    input ${verilog.make_range(reg_addr_size)} address;
    reg ${verilog.make_range(context.max_reg_width)} read_data;
    reg [1:0] read_error;
    begin
        // Initialise return value to 0
        read_data  = ${context.max_reg_width+1}'d0;
        read_error = `REG_ACCESS_OK;
        case (address)
%for group in block.registers:
    %for reg in group.registers:
            // ${group.id}.${reg.id}
            ${reg_addr_size}'h${"%x" % reg.getOffset()}: begin
        %if bladereg.is_bus_readable(reg):
            %for field in reg.fields:
<%              prefix = filters.constStyle(group.id + "_" + reg.id + "_" + field.id) %>\
                %if field.size == 1:
                read_data[`${prefix}_LSB] = \
                %else:
                read_data[`${prefix}_MSB:`${prefix}_LSB] = \
                %endif ## field.size == 1
                %if bladereg.is_block_writeable(reg):
${bladereg.register_field_name(group, reg, field)}_read;
                %else:
${bladereg.register_field_name(group, reg, field)}_write;
                %endif
                %if bladereg.is_active_read(reg):
                ${bladereg.register_field_name(group, reg, field)}_ar = 1'b1;
                %endif ## bladereg.is_active_read(reg)
            %endfor ## field in reg.fields
        %else:
                $display("WARNING: Reading from a write-only register ${group.id}.${reg.id}");
                read_error = `REG_ACCESS_SLVERR;
        %endif ## bladereg.is_bus_readable(reg)
            end
    %endfor ## reg in group.registers
%endfor ## group in block.registers
            default: begin
                $display("WARNING: Reading from unknown register");
                read_data  = ${context.max_reg_width}'h${"%x" % ((1 << context.max_reg_width) - 1)};
                read_error = `REG_ACCESS_DECERR;
            end
        endcase
        register_read = {read_data, read_error};
    end
endfunction

${caller.body()}\
</%module:mod>
</%def>