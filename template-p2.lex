%{
#include <string>
#include <iostream>
#include <cmath>
#include <stack>
#include <variant>
#include <functional>

// ID values for tokens.
// Note: this is usually in a separate header file,
// usually because a parser-generator tool like Bison produces this.

enum Token {
  INT = 1,
  FLOAT,
  ADD,
  SUB,
  MUL,
  DIV,
  MOD,
  EXP
};

// Stack for numbers found while scanning
struct Operand {
  std::variant<int, double> value;
  bool is_integer;

  Operand(std::variant<int, double> v, bool is_int) : value(v), is_integer(is_int) {}
};

std::stack<Operand> ws;

bool apply_operation(std::function<double(double, double)> op) {
  if (ws.size() < 2) {
    return false;
  }

  Operand b = ws.top(); ws.pop();
  Operand a = ws.top(); ws.pop();

  if (b.is_integer && a.is_integer) {
    int val_b = std::get<int>(b.value);
    int val_a = std::get<int>(a.value);
    int res = static_cast<int>(
      op(static_cast<double>(val_a), static_cast<double>(val_b))
    );
    ws.push(Operand(std::variant<int, double>(res), true));
  } else {
    double val_b = std::visit([](auto&& arg) -> double {
      return static_cast<double>(arg);
    }, b.value);

    double val_a = std::visit([](auto&& arg) -> double {
      return static_cast<double>(arg);
    }, a.value);
    
    double res = op(val_a, val_b);
    ws.push(Operand(std::variant<int, double>(res), false));
  }

  return true;
}

%}

%option c++
%option interactive
%option noyywrap
%option nodefault
%option outfile="Scanner.cpp"

%%
[0-9]+ {
  std::string input = std::string(yytext);
  std::variant<int, double> val = std::stoi(input);
  ws.push(Operand(val, true));
  return Token::INT;
}
[0-9]+\.[0-9]+ {
  std::string input = std::string(yytext);
  std::variant<int, double> val = std::stod(input);
  ws.push(Operand(val, false));
  return Token::FLOAT;
}
"+" {
  if (!apply_operation(std::plus<double>())) {
    LexerError("Insufficient # of operands for `+`\n");
    return 0;
  }
  return Token::ADD;
}
"-" {
  if (!apply_operation(std::minus<double>())) {
    LexerError("Insufficient # of operands for `-`\n");
    return 0;
  }
  return Token::SUB;
}
"*" {
  if (!apply_operation(std::multiplies<double>())) {
    LexerError("Insufficient # of operands for `*`\n");
    return 0;
  }
  return Token::MUL;
}
"/" {
  bool res = apply_operation([](double a, double b) -> double {
    if (b == 0) {
      std::cerr << "Error: Division by zero" << std::endl;
      //LexerError("Division by zero.");
      exit(0);
    }
    return a / b;
  });
  if (!res) {
    LexerError("Insufficient # of operands for `/`\n");
    return 0;
  }

  return Token::DIV;
}
"^" {
  bool res = apply_operation([](double a, double b) -> double {
    return std::pow(a, b);
  });
  if (!res) {
    LexerError("Insufficient # of operands for `^`\n");
    return 0;
  }
  return Token::EXP;
}
"%" {
  if (ws.size() < 2) {
    LexerError("Insufficient # of operands for `%`\n");
    return 0;
  }

  Operand b = ws.top(); ws.pop();
  Operand a = ws.top(); ws.pop();

  if (b.is_integer && a.is_integer) {
    int val_a = std::get<int>(a.value);
    int val_b = std::get<int>(b.value);
    int res = val_a % val_b;
    ws.push(Operand(std::variant<int, double>(res), true));
  } else {
    LexerError("Error: cannot perform modulo operation on non-integers.");
    return 0;
  }

  return Token::MOD;
}

[ \t]+ {
  // ignore whitespace
}

\n {
  return 0;
}

. {
  //std::cerr << "Error, unexpected character '" << YYText() << "' encountered.\n";
  //LexerError("Exiting due to unexpected character");
  LexerError("Unexpected Character\n");
}
%%

int main() {
  yyFlexLexer* lexer = new yyFlexLexer(std::cin, std::cout);
  while(lexer->yylex() != 0);

  // Determine if the expression reduced to a single answer or not.
  // Print appropriate messages accordingly.
  if (ws.size() == 1) {
    Operand result = ws.top();
    if (result.is_integer) {
      std::cout << "Result: " << std::get<int>(result.value) << std::endl;
    } else {
      std::cout << "Result: " << std::get<double>(result.value) << std::endl;
    }
  } else {
    std::cerr << "Expression does not reduce to a single answer" << std::endl;
  }
  
  return 0;
}
