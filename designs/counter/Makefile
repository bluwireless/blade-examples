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

# ==============================================================================
# Variables
# ==============================================================================
YAML_SRC_DIRS         := yaml_mod yaml_reg yaml_his
YAML_TOP_LEVELS       := yaml_mod/counter.yaml ../constants/axi4_defines.yaml
RTL_IMP_TEMPLATE_DIRS := imp_src
MAKE_J                ?= 10

# Simulation options
RTL_SRC_DIRS          += src_v tb
RTL_TOP               ?= counter_tb
TRACE_FILE            ?= tb/traces.sav

# ==============================================================================
# Include Rules From Other Makefiles
# ==============================================================================
include ../../flow/Makefile.generate
include ../../flow/Makefile.iverilog