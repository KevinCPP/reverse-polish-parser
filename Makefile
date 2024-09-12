
LEX_FILE = template-p2.lex
LEX_OUTPUT = Scanner.cpp
EXECUTABLE = Scanner.out

CXX = g++
CXXFLAGS = -std=c++20
LEX = flex

all: clean $(EXECUTABLE)
	./$(EXECUTABLE)

$(EXECUTABLE): $(LEX_FILE)
	$(LEX) -o $(LEX_OUTPUT) $(LEX_FILE)
	$(CXX) $(CXXFLAGS) $(LEX_OUTPUT) -o $(EXECUTABLE)

clean:
	rm -f $(LEX_OUTPUT)

.PHONY: all clean
