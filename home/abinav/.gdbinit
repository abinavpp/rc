define asm
	la asm
	la reg
end

define sta
	start
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
	if sizeof($arg0) == 8
		call $arg0->dump()
	else
		call $arg0.dump()
	end
end

define dmr
	if sizeof(TRI) == 8
		call TRI->getName($arg0)
	else
		call TRI.getName($arg0)
	end
end

define numpass
	call getNumContainedPasses()
end

define getpass
	p *getContainedPass($arg0)
end

define u
	up
end

define d
	down
end

skip -gfi /usr/include/c++/*/bits/*.h
# set follow-fork-mode child
set confirm off
tui enable
foc cmd
