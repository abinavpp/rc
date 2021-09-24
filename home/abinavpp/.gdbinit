python

import os

def src(file):
  if os.path.isfile(file):
    gdb.execute('source ' + file)

src(os.environ['HOME'] + '/.pre-gdbinit')
src('/usr/share/gdb/python/gdb/command/pretty_printers.py')
src(os.environ['HOME'] +
    'pj/llvm-project/llvm/utils/gdb-scripts/prettyprinters.py')

class LLDump(gdb.Function):
  def __init__(self):
    super(LLDump, self).__init__("llDump")

  def invoke(self, var, name):
    if var.type.code == gdb.TYPE_CODE_PTR:
      return 'TODO'
    else:
      return 'TODO'

class IsPointer(gdb.Function):
  def __init__(self):
    super(IsPointer, self).__init__("isPointer")

  def invoke(self, var):
    if var.type.code == gdb.TYPE_CODE_PTR:
      return True
    else:
      return False

LLDump()
IsPointer()

end

skip -gfi /usr/include/c++/*/bits/*.h

define asm
  la asm
  la reg
end

define sta
  start
  del
end

define stai
  la asm
  starti
  del
end

define ps
  print (char *) $arg0
end

define ub
  b $arg0
  cont
  del
end

define sub
  start
  ub $arg0
end

define dm
  if $isPointer($arg0)
    call $arg0->dump()
  else
    call $arg0.dump()
  end
end

define u
  up
end

define d
  down
end

define c
  call
end

set follow-fork-mode child
set detach-on-fork off
set confirm off
set disassembly intel

tui enable
foc cmd

python

src(os.environ['HOME'] + '/.post-gdbinit')

end

# vim: ft=python
