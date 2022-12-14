# Here is an example of the simplist project file in the world.  The
# goal is to build an object file from each C/C++ file, then link these
# into a single executable file named 'foo'.

TARGET_APP=SIM
SIM: $(patsubst %.cxx,%.o,$(wildcard *.cxx))
# or you can specify explict object code (.o files) to be used...
# (comment out the line above, uncomment the line below)
#SIM: SIM.o m.o

# Makefile automatically derives a variable named OBJECTS from existing C/C++
# file in the current directory.  You cannot, however, use this variable in
# the dependency because it has not been calculated yet and make will not
# defer its valuation when it is in a dependency.  You simply have to list
# the actual object files.  There are, by the way, ways around this, but I felt
# this would keep this perhaps-already-too-convoluted build template simplist.

