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

Template    :   module.v
Description :   Generate module with ports and basic connectivity.
</%doc>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="blademod" module="helpers.mod_common"/>\
<%namespace name="bladereg" module="helpers.reg_common"/>\
<%namespace name="verilog" file="verilog.v"/>\

## =============================================================================
## module:mod - Declares the boundary of a Verilog module with shattered ports
## =============================================================================
<%def name="mod(block)">\
<%
shattered = blademod.shatter_block_ports(block)

# Create namespaces for different properties of the block
ports  = blademod.create_port_shard_lookup(block)
regs   = bladereg.create_register_shard_lookup(block)

# Identify the main clock and reset ports
clk_port = block.getPrincipalSignal("clock")
rst_port = block.getPrincipalSignal("reset")
clock = blademod.get_port_base_name(clk_port, DFConstants.DIRECTION.INPUT) if clk_port else None
reset = blademod.get_port_base_name(rst_port, DFConstants.DIRECTION.INPUT) if rst_port else None

for entry in iter(caller):
    if entry == None: continue
    # Expose these variables to every caller in the stack
    entry.context._data['params'] = entry.context._kwargs['params'] = params
    entry.context._data['ports']  = entry.context._kwargs['ports'] = ports
    entry.context._data['regs']   = entry.context._kwargs['regs'] = regs
    entry.context._data['clock']  = entry.context._kwargs['clock'] = clock
    entry.context._data['reset']  = entry.context._kwargs['reset'] = reset
%>\
module ${blademod.get_block_class(block)} (
<% local._first = True %>\
%for dirx in shattered.keys():
    // =========================================================================
    // ${dirx[0].upper()+dirx[1:].lower()}put ports
    // =========================================================================
    %for port in shattered[dirx].values():
    // '${port["port"].name}' of type '${port["port"].getInterconnectType().id}'${filters.optComment(port["port"].description, ':')}
        %for shards in port["shards"]:
            %for shard in shards:
                %if shard["width"] == 1:
    ${" " if local._first else ","} ${"%3s" % shard["dir"].lower()}put         ${shard["name"]}
                %else:
    ${" " if local._first else ","} ${"%3s" % shard["dir"].lower()}put [${"%3u" % (shard["width"]-1)}:0] ${shard["name"]}
                %endif
<%              local._first = False %>\
            %endfor
        %endfor
    %endfor
%endfor
);

%if block.children:
// =============================================================================
// Wiring
// =============================================================================
    %for child in block.children:
<%
        io         = blademod.shatter_block_ports(child)
        all_ports  = [x for x in io[DFConstants.DIRECTION.INPUT].values()]
        all_ports += [x for x in io[DFConstants.DIRECTION.OUTPUT].values()]
%>\
        %for port_desc in all_ports:
            %for shards in port_desc["shards"]:
                %for shard in shards:
wire ${verilog.make_range(shard["width"])} ${child.id | filters.varStyle}_${shard["name"]};
                %endfor ## shard in shards
            %endfor ## shards in port_desc["shards"]
        %endfor ## port_desc in all_ports
    %endfor ## child in block.children

// =============================================================================
// Child block instances
// =============================================================================
    %for child in block.children:
<%
        io         = blademod.shatter_block_ports(child)
        first      = True
        all_ports  = [x for x in io[DFConstants.DIRECTION.INPUT].values()]
        all_ports += [x for x in io[DFConstants.DIRECTION.OUTPUT].values()]
%>\
${blademod.get_block_class(child)} m_${child.id | filters.varStyle} (
        %for port_desc in all_ports:
            %for shards in port_desc["shards"]:
                %for shard in shards:
    ${" " if first else ","} .${shard["name"]}(${child.id | filters.varStyle}_${shard["name"]})
<%                  first = False %>\
                %endfor ## shard in shards
            %endfor ## shards in port_desc["shards"]
        %endfor ## port_desc in all_ports
);

    %endfor ## child in block.children
%endif ## block.children
%if block.connections:
// =============================================================================
// Connectivity
// =============================================================================
    %for conn in block.connections:
<%
        end_io     = blademod.shatter_port(conn.end_port, conn.end_index)
        end_prefix = ""
        if conn.end_port.block != block:
            end_prefix = filters.varStyle(conn.end_port.block.id) + "_"
%>\
// ${conn.id.replace("-to-", " -> ")}
        %if conn.isTieOff():
assign {
<%
            first  = True
            width  = 0
%>\
            %for shard in [x for x in end_io if x["dir"] == DFConstants.DIRECTION.INPUT]:
    ${" " if first else ","} ${end_prefix}${shard["name"]}
<%
                first  = False
                width += shard["width"]
%>\
            %endfor
} = ${width}'h${"%x" % conn.start_port.value};
        %else:
<%
            start_io     = blademod.shatter_port(conn.start_port, conn.start_index)
            start_prefix = ""
            if conn.start_port.block != block:
                start_prefix = filters.varStyle(conn.start_port.block.id) + "_"
%>\
            %for start_shard, end_shard in zip(start_io, end_io):
<%
                dir_in = (start_shard["dir"] == DFConstants.DIRECTION.INPUT)
                if conn.start_port.direction == DFConstants.DIRECTION.OUTPUT:
                    dir_in = not dir_in
%>\
                %if dir_in:
assign ${end_prefix}${end_shard["name"]} = ${start_prefix}${start_shard["name"]};
                %else:
assign ${start_prefix}${start_shard["name"]} = ${end_prefix}${end_shard["name"]};
                %endif ## dir_in
            %endfor ## start_shard, end_shard in zip(start_io, end_io)
        %endif ## conn.isTieOff()

    %endfor ## conn in block.connections
%endif ## block.connections
## Only use tie-offs when this is not an 'IMP' block
%if not block.getAttribute('IMP') and (block.getUnconnectedPorts() or block.getUnconnectedChildPorts()):
// =============================================================================
// Tie Offs
// =============================================================================
    %for port in (block.getUnconnectedPorts() + block.getUnconnectedChildPorts()):
        %for i_port in range(port.count):
<%          io = blademod.shatter_port(port, i_port) %>\
            %if port.block == block:
                %for shard in [x for x in io if x["dir"] == DFConstants.DIRECTION.OUTPUT]:
assign ${shard["name"]} = ${shard["width"]}'d0;
                %endfor ## shard in [x for x in io if x["dir"] == DFConstants.DIRECTION.OUTPUT]
            %else:
<%              prefix = filters.varStyle(port.block.id) + "_" %>\
                %for shard in [x for x in io if x["dir"] == DFConstants.DIRECTION.INPUT]:
assign ${prefix}${shard["name"]} = ${shard["width"]}'d0;
                %endfor ## shard in [x for x in io if x["dir"] == DFConstants.DIRECTION.INPUT]
            %endif ## port.block == block
        %endfor ## i_port in range(port.count)
    %endfor ## port in (block.getUnconnectedPorts() + block.getUnconnectedChildPorts())

%endif
${caller.body()}\
endmodule
</%def>\

