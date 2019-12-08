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

// -----------------------------------------------------------------------------
// Group Offset Addresses
// -----------------------------------------------------------------------------
<%filters:tabify separators=" ">\
%for group in block.registers:
`define ${group.id | filters.constStyle}_GRP_OFFSET ${group.offset}
%endfor ## group in block.registers
</%filters:tabify>\

// -----------------------------------------------------------------------------
// Register Offset Addresses
// -----------------------------------------------------------------------------
<%filters:tabify separators=" ">\
%for group in block.registers:
    %for reg in group.registers:
`define ${group.id | filters.constStyle}_${reg.id | filters.constStyle}_OFFSET ${reg.getOffset()}
    %endfor ## reg in group.registers
%endfor ## group in block.registers
</%filters:tabify>\

// -----------------------------------------------------------------------------
// Register Field Parameters
// -----------------------------------------------------------------------------
<%filters:tabify separators=" ">\
%for group in block.registers:
    %for reg in group.registers:
        %for field in reg.fields:
<%          prefix = filters.constStyle(group.id + "_" + reg.id + "_" + field.id) %>\
`define ${prefix}_LSB ${"%x" % field.lsb}
`define ${prefix}_MSB ${field.lsb + field.size - 1}
`define ${prefix}_WIDTH ${field.size}
`define ${prefix}_RESET ${field.size}'h${"%x" % field.reset}
            %for key in field.enum:
`define ${prefix}_ENUM_${key | filters.constStyle} ${field.size}'h${"%x" % field.enum[key].value}
            %endfor ## key in field.enum
        %endfor ## field in reg.fields
    %endfor ## reg in group.registers
%endfor ## group in block.registers
</%filters:tabify>\


