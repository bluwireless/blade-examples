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

from blade_templating.common.rules import rule
from blade_templating.common.generation import generate
from designformat import DFBlock, DFBase, DFInterconnect, DFDefine

def class_style(node):
    return "".join([x.lower().capitalize() for x in node.type.split("_")])

@rule(specific=False, type=DFDefine)
def gen_defs(nodes, project):
    yield generate(nodes, 'defs.vh', f'{project.id}_defs.vh')

@rule(type=DFBlock, attrs={ 'IMP': False })
def gen_rtl_wiring(node, project):
    yield generate(node, 'mod_wiring.v', f'{class_style(node)}.v')

@rule(type=DFBlock, attrs={ 'IMP': True, 'RTL': '*.v*' })
def gen_rtl_imp(node, project):
    yield generate(node, node.getAttribute('RTL'), f'{class_style(node)}Imp.v')
    if node.registers:
        yield generate(node, 'reg_defs.vh', f'{node.type}_reg_defs.vh')
