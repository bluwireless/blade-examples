# Copyright (C) 2019 Blu Wireless Ltd.
# All Rights Reserved.
#
# This file is part of BLADE.
#
# BLADE is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# BLADE is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# BLADE.  If not, see <https://www.gnu.org/licenses/>.
#

import re

from helpers.filters import *
from helpers.common import create_namespace
from designformat import DFConstants

## get_block_class
#  Return the class of a DFBlock, taking account of the 'IMP' attribute.
#  @param context  The Mako context object
#  @param block    The DFBlock instance
#  @param varstyle Whether to return in variable style (default: False)
#
def get_block_class(context, block, varstyle=False):
    class_name = classStyle(None, block.type) if not varstyle else varStyle(None, block.type)
    if varstyle:
        class_name = varStyle(context, class_name)
    if block.getAttribute('IMP'):
        class_name += 'Imp' if not varstyle else '_imp'
    return class_name

## get_port_base_name
#  Return the property name for a port, taking account of the EXPLICIT_NAME
#  attribute. This does not include any indexing of the signal index.
#  @param context   The Mako context object
#  @param port      The DFPort instance
#  @param direction Direction of the port (in/out)
#
def get_port_base_name(context, port, direction):
    intc      = port.getInterconnectType()
    port_name = varStyle(context, port.name)
    if port.getAttribute('EXPLICIT_NAME'):
        if intc.hasMasterRole() and intc.hasSlaveRole():
            port_name = f"{port_name}_{direction.lower()}"
    else:
        port_name = f"m_{port_name}_{direction.lower()}"
    return port_name

## get_port_name
#  Return the property name of a port, taking account of the EXPLICIT_NAME
#  attribute if specified
#  @param context   The Mako context object
#  @param port      The DFPort instance
#  @param index     The signal index within the port
#  @param direction Direction of the port (in/out)
#  @param brackets  Whether or not to use '[..]' (default: True)
#
def get_port_name(context, port, index, direction, brackets=True):
    base_name = get_port_base_name(context, port, direction)
    explicit = port.getAttribute('EXPLICIT_NAME')
    if (explicit and port.count > 1) or not explicit:
        base_name += (f"[{index}]" if brackets else f"_{index}")
    return base_name

## connect_name
#  Return the name of the interconnect signal for connecting between ports
#  @param context The Mako context
#  @param port    The DFPort object that's being tied off
#  @param index   The port index being tied off
#  @param role    The role to create a connection for (master/slave)
#
def connect_name(context, port, index, role):
    # m_<END_PORT>_<END_IDX>_<ROLE>
    name   = f"m_{varStyle(context, port.block.id)}_"
    name  += f"{varStyle(context, port.name)}_{index}"
    name  += f"_{role}"
    return name

## bundle_children
#  The DFBlock description of the hierarchy is fully expanded, so we do not have
#  a native concept of indexing child blocks where instantiation count is > 1.
#  To solve this, re-bundle child modules based on type and ID.
#  @param context The Mako context
#  @param block   The block to rebundle
#
def bundle_children(context, block):
    # First separate all children based on type
    types = {}
    for child in block.children:
        if block.type not in types:
            types[block.type] = []
        types[block.type].append(child)

    # Now for each type, re-bundle instances based on ID
    idx_rgx = re.compile(r"^(.*?)_([0-9]+)$") # Child IDs end with '_<index>'
    bundles = {}
    for type in types.values():
        for block in type:
            parts = idx_rgx.search(block.id).groups()
            if parts[0] not in bundles:
                bundles[parts[0]] = []
            bundles[parts[0]].append(block)

    # Now sort each bundle based on the ID field
    for bundle in bundles.values():
        bundle.sort(key=lambda x: x.id)

    return bundles

## shatter_port
#  Shatter a port into shards on a component by component basis - useful for
#  constructing Verilog block definitions.
#  @param context    The Mako context object
#  @param port       The DFPort to shatter
#  @param port_index The signal index within the port to shatter
#  @param component  If provided, only include shards of this component
#
def shatter_port(context, port, port_index, component=None):
    rev_dir = {
        DFConstants.DIRECTION.INPUT : DFConstants.DIRECTION.OUTPUT,
        DFConstants.DIRECTION.OUTPUT: DFConstants.DIRECTION.INPUT
    }
    def build_shards(intc, dirx, path, suffixes=None):
        suffixes = [] if suffixes == None else suffixes
        # Recognise a 'BOOL' signal and break out early
        if intc.getAttribute('BOOL') and intc.getMasterWidth() == 1 and intc.getSlaveWidth() == 0:
            explicit = port.getAttribute("EXPLICIT_NAME")
            if not explicit or (explicit and port.count > 1):
                path.append(str(port_index))
            return [{
                "name": "_".join(path), "width": 1, "dir": dirx,
                "path": path, "index": 0
            }]
        # Break apart the components
        # NOTE: For compatibility with SystemC always put complex components first
        complex_shards = []
        simple_shards  = []
        for comp in intc.components:
            c_dirx = {
                DFConstants.ROLE.MASTER: dirx,
                DFConstants.ROLE.SLAVE : rev_dir[dirx]
            }[comp.role]
            for i_comp in range(comp.count):
                c_path = path[:] + [(comp.id, i_comp)]
                c_sfix = suffixes + ([str(i_comp)] if comp.count > 1 else [])
                if comp.type == DFConstants.COMPONENT.COMPLEX:
                    complex_shards += build_shards(
                        comp.getReference(), c_dirx, c_path, c_sfix
                    )
                elif comp.type == DFConstants.COMPONENT.SIMPLE:
                    simple_shards.append({
                        "name" : varStyle(context, "_".join(
                            [f"m_{x[0]}" for x in c_path] + [str(port_index)] + c_sfix
                        )),
                        "width": comp.width,
                        "dir"  : c_dirx,
                        "path" : c_path,
                        "index": port_index,
                    })
        return complex_shards + simple_shards
    all_shards = []
    port_shards = build_shards(port.getInterconnectType(), port.direction, [])
    # Filter out shards that don't match the component path
    if component != None:
        parts = [x.strip() for x in component.split('.') if len(x.strip()) > 0]
        match = []
        for shard in port_shards:
            # If the component is deeper than the shard's path, ignore this shard
            if len(parts) > len(shard["path"]): continue
            # See if every part of the component path matches
            matched = True
            for exp, real in zip(parts, shard["path"]):
                # Note that the shard's path is a tuple of name and index
                if exp != real[0]:
                    matched = False
                    break
            # If the paths didn't match, break-out
            if not matched: continue
            # Otherwise store the shard
            match.append(shard)
        port_shards = match
    # Separate shards into inputs and outputs
    in_shards  = []
    out_shards = []
    for shard in (x for x in port_shards if x["dir"] == DFConstants.DIRECTION.INPUT):
        shard["name"] = (
            get_port_base_name(context, port, DFConstants.DIRECTION.INPUT) +
            (f"_{shard['name']}" if len(shard["name"]) > 0 else "")
        )
        shard["path"] = [(port.name, port_index)] + shard["path"]
        in_shards.append(shard)
    for shard in (x for x in port_shards if x["dir"] == DFConstants.DIRECTION.OUTPUT):
        shard["name"] = (
            get_port_base_name(context, port, DFConstants.DIRECTION.OUTPUT) +
            (f"_{shard['name']}" if len(shard["name"]) > 0 else "")
        )
        shard["path"] = [(port.name, port_index)] + shard["path"]
        out_shards.append(shard)
    # Glue the ports together in an order that matches the SystemC design
    if port.direction == DFConstants.DIRECTION.INPUT:
        all_shards = in_shards + out_shards
    else:
        all_shards = out_shards + in_shards
    return all_shards

## shatter_block_ports
#  Shatter all ports of the block using the 'shatter_port' function
#  @param context The Mako context object
#  @param block   The DFBlock to process
#
def shatter_block_ports(context, block):
    shattered = {
        DFConstants.DIRECTION.INPUT : { },
        DFConstants.DIRECTION.OUTPUT: { }
    }
    def shatter_all(port):
        shards = []
        for i_port in range(port.count):
            shards.append(shatter_port(context, port, i_port))
        return shards
    for port in block.ports.input:
        shattered[DFConstants.DIRECTION.INPUT][port.name] = {
            "port": port, "shards": shatter_all(port)
        }
    for port in block.ports.output:
        shattered[DFConstants.DIRECTION.OUTPUT][port.name] = {
            "port": port, "shards": shatter_all(port)
        }
    return shattered

## create_port_shard_lookup
#  Create a namespace for looking up port's shard names
#  @param context The Mako context object
#  @param block   The DFBlock to process
#
def create_port_shard_lookup(context, block):
    # First shatter the ports
    shattered = shatter_block_ports(context, block)
    # Now walk through all of the shards creating a data structure
    lookup = {}
    for port_dir in shattered.values():
        for port in port_dir.values():
            for shardset in port["shards"]:
                for shard in shardset:
                    def resolve_path(path, obj):
                        seg = path[0]
                        if seg[0] not in obj: obj[seg[0]] = []
                        if len(path) == 1:
                            return obj[seg[0]]
                        else:
                            if seg[1] >= len(obj[seg[0]]):
                                obj[seg[0]].append({})
                            return resolve_path(path[1:], obj[seg[0]][seg[1]])
                    point = resolve_path(shard["path"], lookup)
                    point.append(shard["name"])
    # Convert the lookup into a namespace
    return create_namespace(lookup)