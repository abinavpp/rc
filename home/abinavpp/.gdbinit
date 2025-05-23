python

import os

def src(file):
  if os.path.isfile(file):
    gdb.execute('source ' + file)

src(os.environ['HOME'] + '/.pre-gdbinit')
src('/usr/share/gdb/python/gdb/command/pretty_printers.py')
src(os.environ['HOME'] +
    '/pj/llvm-project/llvm/utils/gdb-scripts/prettyprinters.py')
src(os.environ['HOME'] +
    '/pj/llvm-project/mlir/utils/gdb-scripts/prettyprinters.py')

class IsPointer(gdb.Function):
  def __init__(self):
    super(IsPointer, self).__init__("isPointer")

  def invoke(self, var):
    if var.type.code == gdb.TYPE_CODE_PTR:
      return True
    else:
      return False

IsPointer()

end

define q
  set confirm off
  quit
end

define asm
  layout asm
end

define sp
  layout split
end

define sta
  start
  delete
end

define stai
  layout asm
  starti
  delete
end

define ub
  break $arg0
  continue
  delete
end

define rub
  break $arg0
  run
  delete
end

define dm
  if $isPointer($arg0)
    call $arg0->dump()
  else
    call $arg0.dump()
  end
end

# TODO: Integrate this with dm()
define dmr
  p getRegisterName(TRI, $arg0).c_str()
end

define u
  up
end

define d
  down
end

set breakpoint pending on
set follow-fork-mode child
set detach-on-fork off
set disassembly intel
set auto-load safe-path /
set index-cache enabled
set print elements 0
set debuginfod enabled on

tui enable
foc cmd

python src(os.environ['HOME'] + '/.post-gdbinit')
