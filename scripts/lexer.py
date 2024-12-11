import os
import sys

class Position():
    def __init__(self) -> None:
        self.line = 1
        self.col = 1

class Token():
    def __init__(self, type, value) -> None:
        self.type = type
        self.value = value
        self.pos = Position()
    pass

with open('/home/pluto/proj/lnrv/rtl/core/top/lnrv_core.v', 'r') as f:
    for c in f.read():
        print('c = %s'%c)