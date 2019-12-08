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

from helpers import natural_sort
from helpers.filters import *
from helpers.common import create_namespace
from designformat import DFConstants, DFBlock, DFRegister, DFRegisterGroup, DFRegisterField

# There are some constants that don't map directly to DesignFormat & are stored
# as attributes, we grab the Phhidle constants map so that we can test these!
from blade.schema import CONSTANTS as TagConstants

MODE = DFConstants.ACCESS

## register_field_name
#  Construct the name for a DFRegisterField
#  @param context The Mako context object
#  @param field   The DFRegisterField to process
#
def register_field_name(context, grp, reg, field):
    assert isinstance(field, DFRegisterField)
    return f"m_{varStyle(None, grp.id)}_{varStyle(None, reg.id)}_{varStyle(None, field.id)}"

## create_register_shard_lookup
#  Shatter every field of every register in every group attached to the block
#  @param context The Mako context object
#  @param block   The DFBlock to process
#
def create_register_shard_lookup(context, block):
    shattered = {}
    idx_rgx   = re.compile(r"^(.*?)_([0-9]+)$")
    for group in block.registers:
        assert isinstance(group, DFRegisterGroup)
        # Pickup if there is an index suffix e.g '_1'
        grp_data = idx_rgx.findall(group.id)
        grp_name = grp_data[0][0] if grp_data else group.id
        grp_idx  = int(grp_data[0][1]) if grp_data else 0
        # Insert an entry to capture this group's details
        if not grp_name in shattered: shattered[grp_name] = []
        assert len(shattered[grp_name]) == grp_idx
        grp_entry = {}
        shattered[grp_name].append(grp_entry)
        # Iterate through the registers
        for register in group.registers:
            assert isinstance(register, DFRegister)
            # Pickup if the register has an index suffix
            reg_data = idx_rgx.findall(register.id)
            reg_name = reg_data[0][0] if reg_data else register.id
            reg_idx  = int(reg_data[0][1]) if reg_data else 0
            # Insert an entry to capture this register's details
            if not reg_name in grp_entry: grp_entry[reg_name] = []
            reg_entry = {}
            grp_entry[reg_name].append(reg_entry)
            # Iterate through the fields
            for field in register.fields:
                assert isinstance(field, DFRegisterField)
                reg_entry[field.id] = register_field_name(context, group, register, field)
    return create_namespace(shattered)

# ==============================================================================
# Register access modes
# ==============================================================================

## is_block_readable
#  Determines if this register's value can be read by the block.
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_block_readable(context, reg):
    return reg.access.block in (MODE.RW, MODE.RO) # Doesn't support 'active' modes

## is_block_writeable
#  Determines if this register's value can be set by the block.
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_block_writeable(context, reg):
    return reg.access.block in (MODE.RW, MODE.WO) # Doesn't support 'active' modes

## is_bus_readable
#  Determines if this register's value can be read by the bus.
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_bus_readable(context, reg):
    return reg.access.bus in (MODE.RW, MODE.RO, MODE.AR, MODE.ARW)

## is_bus_writeable
#  Determines if this register's value can be written by the bus.
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_bus_writeable(context, reg):
    return reg.access.bus in (MODE.RW, MODE.WO, MODE.AW, MODE.WC, MODE.WS, MODE.ARW)

## has_write_strobe
#  Determine if this register should have a write strobe
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def has_write_strobe(context, reg):
    return (
        reg.access.bus in (MODE.AW, MODE.ARW) and
        is_block_readable(None, reg) and
        is_bus_writeable(None, reg)
    )

## is_active_write
#  Does the block need notification when the value changes?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_active_write(context, reg):
    return reg.access.bus in (MODE.ARW, MODE.AW)

## has_read_strobe
#  Determine if this register should have a read strobe
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def has_read_strobe(context, reg):
    return (
        reg.access.bus in (MODE.AR, MODE.ARW) and
        is_block_writeable(None, reg) and
        is_bus_readable(None, reg)
    )

## is_active_read
#  Does the block need notification when the value is read?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_active_read(context, reg):
    return reg.access.bus in (MODE.ARW, MODE.AR)

## has_strobes
#  Does this register have either read or write strobes?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def has_strobes(context, reg):
    return (has_write_strobe(context, reg) or has_read_strobe(context, reg))

## is_active
#  Does this register have read or write active signals?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_active(context, reg):
    return (is_active_write(context, reg) or is_active_read(context, reg))

## has_any_strobes
#  Does any block have any registers with either read or write strobes?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def has_any_strobes(context, block):
    return (True in (has_strobes(None, x) for x in get_all_registers(None, block)))

## has_any_active
#  Does this block have any registers which have read or write active signals?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def has_any_active(context, block):
    return (True in (is_active(context, x) for x in get_all_registers(context, block)))

# ==============================================================================
# Automatically expanded interrupt registers
# ==============================================================================

## is_interrupt
#  Is this an expanded interrupt register?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_interrupt(context, reg):
    return (reg.getAttribute('interrupt') != None)

## has_interrupt_registers
#  Does this block offer interrupt registers
#  @param context The Mako context object
#  @param block   The DFBlock instance
#
def has_interrupt_registers(context, block):
    return (True in (is_interrupt(None, x) for x in get_all_registers(None, block)))

## get_interrupt_register
#  Get a different register from the expanded set that is associated to another
#  register. For example, passing an MSTA register and asking for ENABLE will
#  return the ENABLE register that is used to generate its value from the RSTA.
#  @param context The Mako context object
#  @param block   The block to examine
#  @param reg     The register to find an associate to
#  @param desired The type to associate (MSTA, RSTA, ENABLE, etc.)
#
def get_interrupt_register(context, block, reg, desired):
    desired  = desired.strip().lower()
    all_regs = get_all_registers(context, block)
    for found in (
        x for x in all_regs if x.getAttribute('parent') == reg.getAttribute('parent')
    ):
        if found.getAttribute('interrupt').strip().lower() == desired:
            return found
    return None

## is_masked_interrupt
#  Determines if this is a masked interrupt status register (msta).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_masked_interrupt(context, reg):
    return (reg.getAttribute('interrupt') == 'msta')

## is_raw_interrupt
#  Determines if this is a unmasked interrupt status register (rsta).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_raw_interrupt(context, reg):
    return (reg.getAttribute('interrupt') == 'rsta')

## is_interrupt_mask
#  Determines if this is a interrupt masking register (enable).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_interrupt_mask(context, reg):
    return (reg.getAttribute('interrupt') == 'enable')

## is_interrupt_set
#  Determines if this is a register to set the interrupt state (set).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_interrupt_set(context, reg):
    return (reg.getAttribute('interrupt') == 'set')

## is_interrupt_clear
#  Determines if this is a register to clear the interrupt state (clear).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_interrupt_clear(context, reg):
    return (reg.getAttribute('interrupt') == 'clear')

## is_interrupt_level
#  Determines if this is an interrupt level sensitivity register (level).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_interrupt_level(context, reg):
    return (reg.getAttribute('interrupt') == 'level')

## is_interrupt_mode
#  Determines if this is an interrupt mode (level/edge) register (mode).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_interrupt_mode(context, reg):
    return (reg.getAttribute('interrupt') == 'mode')

# ==============================================================================
# Automatically expanded set-clear registers
# ==============================================================================

## has_setclear_registers
#  Does this block offer set-clear registers
#  @param context The Mako context object
#  @param block   The DFBlock instance
#
def has_setclear_registers(context, block):
    return (True in (is_setclear(None, x) for x in get_all_registers(None, block)))

## is_setclear
#  Is this an expanded set-clear register?
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_setclear(context, reg):
    return (reg.getAttribute('setclear') != None)

## get_setclear_register
#  Get a different register from the expanded set that is associated to another
#  register. For example, passing a STATUS register and asking for SET will
#  return the SET register that is used to generate its value from the STATUS.
#  @param context The Mako context object
#  @param block   The block to examine
#  @param reg     The register to find an associate to
#  @param desired The type to associate (STATUS, SET, CLEAR, etc.)
#
def get_setclear_register(context, block, reg, desired):
    desired  = desired.strip().lower()
    all_regs = get_all_registers(context, block)
    for found in (
        x for x in all_regs if x.getAttribute('parent') == reg.getAttribute('parent')
    ):
        if found.getAttribute('setclear').strip().lower() == desired:
            return found
    return None

## is_setclear_status
#  Determines if this is a set-clear status register (status).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_setclear_status(context, reg):
    return (reg.getAttribute('setclear') == 'status')

## is_setclear_set
#  Determines if this is a set-clear set register (set).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_setclear_set(context, reg):
    return (reg.getAttribute('setclear') == 'set')

## is_setclear_clear
#  Determines if this is a set-clear clear register (clear).
#  @param context The Mako context object
#  @param reg     The DFRegister instance
#
def is_setclear_clear(context, reg):
    return (reg.getAttribute('setclear') == 'clear')
