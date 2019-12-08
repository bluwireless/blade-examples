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

class Namespace(object):
    """ Create a namespace from a dictionary """

    __raw_data  = []
    __data_keys = []

    def __init__(self, data):
        assert isinstance(data, dict)
        self.__raw_data = data

    def keys(self):
        return self.__raw_data.keys()

    def values(self):
        return self.__raw_data.values()

    def __repr__(self):
        return self.__raw_data.__repr__()

    def __getitem__(self, key):
        """ Override the [...] subscript accessor """
        if key in self.__raw_data:
            return self.__raw_data[key]
        else:
            raise KeyError("No value known for key: " + key)

    def __getattribute__(self, key):
        """ Override the '.' attribute accessor """
        if "__" not in key and key in self.__raw_data:
            return self.__raw_data[key]
        else:
            return super(Namespace, self).__getattribute__(key)

    def __setattr__(self, key, value):
        """ Protect data attributes from being overwritten """
        if key in self.__raw_data:
            raise AttributeError(f"{key} is a protected property")
        else:
            super(Namespace, self).__setattr__(key, value)

    def __iter__(self):
        """ Allow iteration through the stored data """
        self.__data_keys  = [x for x in self.__raw_data.keys()]
        return self

    def __next__(self):
        if len(self.__data_keys) > 0:
            return self.__data_keys.pop(0)
        else:
            raise StopIteration()
    next = __next__

class NamespaceList(list):
    """ Create a namespace list with some useful behaviours """

    def __init__(self, *args):
        if len(args) == 1 and isinstance(args[0], list):
            super(NamespaceList, self).__init__(args[0])
        else:
            super(NamespaceList, self).__init__(args)

    def __repr__(self):
        if len(self) == 1:
            return str(self[0])
        else:
            return super(NamespaceList, self).__repr__()

    def __getattribute__(self, key):
        """ If list only contains 1 attribute, skip to it """
        if "__" not in key and len(self) == 1:
            try:
                return self[0][key]
            except Exception:
                pass
        return super(NamespaceList, self).__getattribute__(key)

def create_namespace(data):
    """ Convert a map object and recursively convert it to a namespace """
    if not isinstance(data, dict): return data
    digested = {}
    for key in data:
        if isinstance(data[key], dict):
            digested[key] = create_namespace(data[key])
        elif isinstance(data[key], list):
            digested[key] = NamespaceList([create_namespace(x) for x in data[key]])
        else:
            digested[key] = data[key]
    return Namespace(digested)
