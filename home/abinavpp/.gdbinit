source ~/.pre-gdbinit

python
class LLDump(gdb.Function):
  def __init__(self):
    super(LLDump, self).__init__("llDump")

  def invoke(self, var, name):
    # sym = gdb.lookup_symbol(name)[0]
    if var.type.code == gdb.TYPE_CODE_PTR:
      # gdb.execute('call %s->dump()' % sym.name)
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

define llgetpass
  p *getContainedPass($arg0)
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

source /usr/share/gdb/python/gdb/command/pretty_printers.py

python
import os
gdb.execute('source ' + os.environ['LLVM_DEV'] +
  '/llvm-main/llvm/utils/gdb-scripts/prettyprinters.py')
end

skip -gfi /usr/include/c++/*/bits/*.h

set follow-fork-mode child
set detach-on-fork off
set confirm off
set disassembly intel

source ~/.post-gdbinit

tui enable
foc cmd