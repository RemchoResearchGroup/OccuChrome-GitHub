CXX=clang++
RM=rm -f

CXXFLAGS=-Wall -Wextra -std=c++11 -I/usr/include/boost -Iinclude/ -O2 -g
LDFLAGS=`pkg-config --cflags opencv` `pkg-config --libs opencv sqlite3` -lboost_system -lboost_timer -lboost_serialization

SRCS=$(shell find src/ -type f -name '*.cpp')
OBJS=$(subst .cpp,.o,$(SRCS))

SRCSIMG=test/imgtest.cpp
OBJSIMG=test/imgtest.o

SRCSREGR=test/regrtest.cpp
OBJSREGR=test/regrtest.o

imgtest: $(OBJS) $(OBJSIMG)
	$(CXX) $(CXXFLAGS) -o imgtest $(OBJS) $(OBJSIMG) $(LDFLAGS)

regrtest: $(OBJS) $(OBJSREGR)
	$(CXX) $(CXXFLAGS) -o regrtest $(OBJS) $(OBJSREGR) $(LDFLAGS)

depend: .depend

.depend: $(SRCS) $(SRCSIMG) $(SRCSREGR)
	rm -f ./.depend
	$(CXX) $(CXXFLAGS) -MM $^>>./.depend;

clean:
	$(RM) $(OBJS) $(OBJSIMG) $(OBJSREGR)

dist-clean: clean
	$(RM) *~ .dependtool

include .depend
