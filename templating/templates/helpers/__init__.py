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

## natural_sort
#  Define a sort function that correctly sorts strings containing numbers. This
#  was adapted from https://stackoverflow.com/questions/5967500
#  @param df_obj The DesignFormat item to consider (expecting object with 'id')
#
def natural_sort(df_obj):
    def atoi(text):
        return int(text) if text.isdigit() else text
    return [atoi(c) for c in re.split('(\d+)', df_obj.id)]
