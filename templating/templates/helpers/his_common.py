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

from helpers.filters import *
from designformat import DFConstants

## comp_prop
#  Create a component property-style name, if count is 1 then we don't index -
#  but if count is greater than 1 then we suffix with '[x]'
#  @param context      The Mako context object
#  @param comp         The signal component to create a name for
#  @param index        The index of the signal
#  @param use_brackets Whether to use brackets '[...]' or an underscore (default: True)
#
def comp_prop(context, comp, index, use_brackets=True):
    if comp.count == 1:
        return propertyStyle(context, comp.id)
    else:
        index_str = f"[{index}]" if use_brackets else f"_{index}"
        return propertyStyle(context, comp.id) + index_str

## comp_var
#  Create a component variable-style name, if count is 1 then we don't index -
#  but if count is greater than 1 then we suffix with '[x]'
#  @param context The Mako context object
#  @param comp    The signal component to create a name for
#  @param index   The index of the signal
#  @param use_brackets Whether to use brackets '[...]' or an underscore (default: True)
#
def comp_var(context, comp, index, use_brackets=True):
    name = varStyle(context, comp.id)
    if comp.count > 1:
        name += f"_{index}" if comp.isComplex() or not use_brackets else f"[{index}]"
    if comp.isComplex():
        name += "_"
    return name

## get_sense_components
#  Get components that align to a certain sense (master/slave) and filtering for
#  either complex or simple elements.
#  @param context      The Mako context object
#  @param interconnect The DFInterconnect object
#  @param sense        Master/slave sense to extract signals for
#  @param is_complex   Control whether simple or complex components are returned
#
def get_sense_components(context, interconnect, sense, is_complex):
    return [
        x for x in interconnect.getRoleComponents(sense) if x.isComplex() == is_complex
    ]
