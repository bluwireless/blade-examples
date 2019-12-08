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
from mako.runtime import supports_caller, capture

## tabify
#  Force lines of text into certain columns of alignment by inserting spaces
#  before certain 'separator' characters. Only tabify if separator is preceeded
#  by a whitespace character.
#  @param context    The Mako context object
#  @param separators The list of separators to tabify
#
@supports_caller
def tabify(context, separators="", **kwargs):
    lines = capture(context, context['caller'].body).splitlines(True)
    for sep in separators:
        true_sep = ' '+sep if sep != ' ' else sep
        # Break every line into sections based on this separator
        line_parts = [x.split(true_sep) for x in lines]
        max_widths = []
        for parts in line_parts:
            for i in range(len(parts)):
                if i >= len(max_widths):
                    max_widths.append(len(parts[i]))
                elif len(parts[i]) > max_widths[i]:
                    max_widths[i] = len(parts[i])
        # Pad out each section of each line to match the maximum width
        lines = []
        for parts in line_parts:
            result = ""
            for i in range(len(parts)-1):
                padding  = ' '*(max_widths[i] - len(parts[i]))
                result  += f"{parts[i]}{padding} {sep}"
            result += parts[-1]
            lines.append(result)
    return ''.join(lines)

## indent
#  Automatically indent all lines to the specified level, lines are trimmed first
#  so that indentation is uniform. Every level of indentation is equivalent to
#  four spaces.
#  @param context The Mako context object
#  @param level   The level to indent to
#
@supports_caller
def indent(context, level=1, **kwargs):
    spaces = int(level) * 4
    lines  = capture(context, context['caller'].body).splitlines(True)
    output = []
    for line in lines:
        output.append((' ' * spaces) + line.strip())
    return '\n'.join(output)

## varStyle
#  Convert string into a variable style - all lowercase with sections separated
#  by underscores.
#  @param src The original string
#
def varStyle(context, src):
    rgx_camel = re.compile(r"([a-z0-9][A-Z])")
    matches   = rgx_camel.findall(src)
    for match in matches:
        cleaned = f"{match[0]}_{match[1].lower()}"
        src     = src.replace(match, cleaned, 1)
    return src.lower().strip().replace(" ","_")

## constStyle
#  Convert string into a constant style - all uppercase with sections separated
#  by underscores.
#  @param src The original string
#
def constStyle(context, src):
    return varStyle(context, src).upper()

## classStyle
#  Convert string into a class style - first letter of every word is uppercase
#  and all other letters are lowercase. Usage of '_' is removed.
#  @param src The original string
#
def classStyle(context, src):
    bits = src.strip().split('_')
    res = []
    for bit in bits:
        res.append(bit.capitalize())
    return ''.join(res)

## propertyStyle
#  Convert a string to a property style - like a variable style, but prefixed
#  with 'm_'.
#  @param src The original string
#
def propertyStyle(context, src):
    return f"m_{varStyle(context, src)}"

## methodStyle
#  Convert a string to method style - like a class style, but with the very first
#  letter in lowercase.
#  @param src The original string
#
def methodStyle(context, src):
    base = classStyle(context, src)
    return (base[0].lower() + base[1:])


## optComment
#  An produce an optional comment, if the text is non-empty.
#  @param context The Mako context object
#  @param text    The text of the comment
#  @param comment The comment delimiter (default: //)
#
def optComment(context, text, comment='//'):
    return f"{comment} {text.strip()}" if text != None and len(text.strip()) > 0 else ""
