// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
const CONST_EVAL_I32_MIN : Int64 = -2147483648L

///|
const CONST_EVAL_I32_MAX : Int64 = 2147483647L

///|
const CONST_EVAL_U32_MAX : Int64 = 4294967295L

///|
priv enum ConstEvalToken {
  At
  LeftParen
  RightParen
  LeftBrace
  RightBrace
  Colon
  Semi
  Comma
  Equal
  EqualEqual
  Bang
  BangEqual
  Less
  LessEqual
  LeftShift
  Greater
  GreaterEqual
  RightShift
  Amp
  AmpAmp
  Pipe
  PipePipe
  Caret
  Plus
  Minus
  Star
  Slash
  Percent
  Tilde
  Arrow
  Ident(String)
  Number(String)
}

///|
fn const_eval_is_whitespace(code : Int) -> Bool {
  code == 32 || code == 9 || code == 10 || code == 13
}

///|
fn const_eval_is_digit(code : Int) -> Bool {
  code >= 48 && code <= 57
}

///|
fn const_eval_is_identifier_start(code : Int) -> Bool {
  (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || code == 95
}

///|
fn const_eval_is_identifier_char(code : Int) -> Bool {
  const_eval_is_identifier_start(code) || const_eval_is_digit(code)
}

///|
fn const_eval_is_number_char(code : Int) -> Bool {
  const_eval_is_identifier_char(code) || code == 46
}

///|
fn const_eval_lex(
  source : String,
) -> Array[ConstEvalToken] raise WeslCompileError {
  let tokens : Array[ConstEvalToken] = []
  let mut index = 0
  while index < source.length() {
    let code = source.code_unit_at(index).to_int()
    if const_eval_is_whitespace(code) {
      index += 1
      continue
    }
    if code == 47 &&
      index + 1 < source.length() &&
      source.code_unit_at(index + 1).to_int() == 47 {
      index += 2
      while index < source.length() && source.code_unit_at(index).to_int() != 10 {
        index += 1
      }
      continue
    }
    match code {
      64 => {
        tokens.push(ConstEvalToken::At)
        index += 1
      }
      40 => {
        tokens.push(ConstEvalToken::LeftParen)
        index += 1
      }
      41 => {
        tokens.push(ConstEvalToken::RightParen)
        index += 1
      }
      123 => {
        tokens.push(ConstEvalToken::LeftBrace)
        index += 1
      }
      125 => {
        tokens.push(ConstEvalToken::RightBrace)
        index += 1
      }
      58 => {
        tokens.push(ConstEvalToken::Colon)
        index += 1
      }
      59 => {
        tokens.push(ConstEvalToken::Semi)
        index += 1
      }
      44 => {
        tokens.push(ConstEvalToken::Comma)
        index += 1
      }
      61 =>
        if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 61 {
          tokens.push(ConstEvalToken::EqualEqual)
          index += 2
        } else {
          tokens.push(ConstEvalToken::Equal)
          index += 1
        }
      33 =>
        if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 61 {
          tokens.push(ConstEvalToken::BangEqual)
          index += 2
        } else {
          tokens.push(ConstEvalToken::Bang)
          index += 1
        }
      60 =>
        if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 60 {
          tokens.push(ConstEvalToken::LeftShift)
          index += 2
        } else if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 61 {
          tokens.push(ConstEvalToken::LessEqual)
          index += 2
        } else {
          tokens.push(ConstEvalToken::Less)
          index += 1
        }
      62 =>
        if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 62 {
          tokens.push(ConstEvalToken::RightShift)
          index += 2
        } else if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 61 {
          tokens.push(ConstEvalToken::GreaterEqual)
          index += 2
        } else {
          tokens.push(ConstEvalToken::Greater)
          index += 1
        }
      38 =>
        if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 38 {
          tokens.push(ConstEvalToken::AmpAmp)
          index += 2
        } else {
          tokens.push(ConstEvalToken::Amp)
          index += 1
        }
      124 =>
        if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 124 {
          tokens.push(ConstEvalToken::PipePipe)
          index += 2
        } else {
          tokens.push(ConstEvalToken::Pipe)
          index += 1
        }
      94 => {
        tokens.push(ConstEvalToken::Caret)
        index += 1
      }
      43 => {
        tokens.push(ConstEvalToken::Plus)
        index += 1
      }
      42 => {
        tokens.push(ConstEvalToken::Star)
        index += 1
      }
      45 =>
        if index + 1 < source.length() &&
          source.code_unit_at(index + 1).to_int() == 62 {
          tokens.push(ConstEvalToken::Arrow)
          index += 2
        } else {
          tokens.push(ConstEvalToken::Minus)
          index += 1
        }
      47 => {
        tokens.push(ConstEvalToken::Slash)
        index += 1
      }
      37 => {
        tokens.push(ConstEvalToken::Percent)
        index += 1
      }
      126 => {
        tokens.push(ConstEvalToken::Tilde)
        index += 1
      }
      _ =>
        if const_eval_is_identifier_start(code) {
          let start = index
          index += 1
          while index < source.length() &&
                const_eval_is_identifier_char(
                  source.code_unit_at(index).to_int(),
                ) {
            index += 1
          }
          tokens.push(ConstEvalToken::Ident(source[start:index].to_owned()))
        } else if const_eval_is_digit(code) {
          let start = index
          index += 1
          while index < source.length() &&
                const_eval_is_number_char(source.code_unit_at(index).to_int()) {
            index += 1
          }
          tokens.push(ConstEvalToken::Number(source[start:index].to_owned()))
        } else {
          raise WeslCompileError::Parse(
            "unsupported const-eval token `\{source[index:index + 1].to_owned()}`",
          )
        }
    }
  }
  tokens
}

///|
priv struct ConstEvalParser {
  mut rest : ArrayView[ConstEvalToken]
}

///|
fn ConstEvalParser::new(tokens : Array[ConstEvalToken]) -> ConstEvalParser {
  ConstEvalParser::{ rest: tokens[:] }
}

///|
fn ConstEvalParser::view(self : ConstEvalParser) -> ArrayView[ConstEvalToken] {
  self.rest
}

///|
fn ConstEvalParser::update_view(
  self : ConstEvalParser,
  rest : ArrayView[ConstEvalToken],
) -> Unit {
  self.rest = rest
}

///|
fn[A] ConstEvalParser::error(
  self : ConstEvalParser,
  message : String,
) -> A raise WeslCompileError {
  ignore(self)
  raise WeslCompileError::Parse(message)
}

///|
priv enum ConstEvalType {
  AbstractInt
  AbstractFloat
  Bool
  I32
  U32
  F32
}

///|
priv enum ConstEvalExpr {
  Literal(String)
  Binding(String)
  UnaryNeg(ConstEvalExpr)
  UnaryNot(ConstEvalExpr)
  UnaryBitNot(ConstEvalExpr)
  Binary(ConstEvalBinaryOp, ConstEvalExpr, ConstEvalExpr)
  Call(String, Array[ConstEvalExpr])
}

///|
priv enum ConstEvalBinaryOp {
  Add
  Sub
  Mul
  Div
  Mod
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
  Shl
  Shr
  BitAnd
  BitOr
  BitXor
  LogicalAnd
  LogicalOr
}

///|
priv struct ConstEvalBinding {
  name : String
  declared_type : ConstEvalType?
  expr : ConstEvalExpr
}

///|
priv struct ConstEvalParam {
  name : String
  declared_type : ConstEvalType
}

///|
priv enum ConstEvalStatement {
  Binding(ConstEvalBinding)
  Return(ConstEvalExpr)
}

///|
priv struct ConstEvalFunction {
  name : String
  params : Array[ConstEvalParam]
  return_type : ConstEvalType
  statements : Array[ConstEvalStatement]
}

///|
fn ConstEvalParser::parse_type(
  self : ConstEvalParser,
) -> ConstEvalType raise WeslCompileError {
  match self.view() {
    [Ident("bool"), .. rest] => {
      self.update_view(rest)
      ConstEvalType::Bool
    }
    [Ident("i32"), .. rest] => {
      self.update_view(rest)
      ConstEvalType::I32
    }
    [Ident("u32"), .. rest] => {
      self.update_view(rest)
      ConstEvalType::U32
    }
    [Ident("f32"), .. rest] => {
      self.update_view(rest)
      ConstEvalType::F32
    }
    _ => self.error("expected const-eval type")
  }
}

///|
fn ConstEvalParser::parse_primary(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  match self.view() {
    [Number(text), .. rest] => {
      self.update_view(rest)
      ConstEvalExpr::Literal(text)
    }
    [Ident("true"), .. rest] => {
      self.update_view(rest)
      ConstEvalExpr::Literal("true")
    }
    [Ident("false"), .. rest] => {
      self.update_view(rest)
      ConstEvalExpr::Literal("false")
    }
    [Ident(name), LeftParen, .. rest] => {
      self.update_view(rest)
      let args : Array[ConstEvalExpr] = []
      if self.view() is [RightParen, .. after_empty] {
        self.update_view(after_empty)
        return ConstEvalExpr::Call(name, args)
      }
      while true {
        args.push(self.parse_expression())
        match self.view() {
          [Comma, .. after_comma] => self.update_view(after_comma)
          [RightParen, .. after_paren] => {
            self.update_view(after_paren)
            break
          }
          _ => self.error("expected `,` or `)` in const-eval argument list")
        }
      }
      ConstEvalExpr::Call(name, args)
    }
    [Ident(name), .. rest] => {
      self.update_view(rest)
      ConstEvalExpr::Binding(name)
    }
    [LeftParen, .. rest] => {
      self.update_view(rest)
      let expr = self.parse_expression()
      match self.view() {
        [RightParen, .. after_paren] => {
          self.update_view(after_paren)
          expr
        }
        _ => self.error("expected `)` in const-eval expression")
      }
    }
    _ => self.error("expected const-eval primary expression")
  }
}

///|
fn ConstEvalParser::parse_unary(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  match self.view() {
    [Minus, .. rest] => {
      self.update_view(rest)
      ConstEvalExpr::UnaryNeg(self.parse_unary())
    }
    [Bang, .. rest] => {
      self.update_view(rest)
      ConstEvalExpr::UnaryNot(self.parse_unary())
    }
    [Tilde, .. rest] => {
      self.update_view(rest)
      ConstEvalExpr::UnaryBitNot(self.parse_unary())
    }
    _ => self.parse_primary()
  }
}

///|
fn ConstEvalParser::parse_multiplicative(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_unary()
  for rest = self.view() {
    match rest {
      [Star, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Mul,
          expr,
          self.parse_unary(),
        )
        continue self.view()
      }
      [Slash, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Div,
          expr,
          self.parse_unary(),
        )
        continue self.view()
      }
      [Percent, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Mod,
          expr,
          self.parse_unary(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_additive(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_multiplicative()
  for rest = self.view() {
    match rest {
      [Plus, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Add,
          expr,
          self.parse_multiplicative(),
        )
        continue self.view()
      }
      [Minus, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Sub,
          expr,
          self.parse_multiplicative(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_shift(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_additive()
  for rest = self.view() {
    match rest {
      [LeftShift, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Shl,
          expr,
          self.parse_additive(),
        )
        continue self.view()
      }
      [RightShift, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Shr,
          expr,
          self.parse_additive(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_relational(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_shift()
  for rest = self.view() {
    match rest {
      [Less, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Lt,
          expr,
          self.parse_shift(),
        )
        continue self.view()
      }
      [LessEqual, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Le,
          expr,
          self.parse_shift(),
        )
        continue self.view()
      }
      [Greater, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Gt,
          expr,
          self.parse_shift(),
        )
        continue self.view()
      }
      [GreaterEqual, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Ge,
          expr,
          self.parse_shift(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_equality(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_relational()
  for rest = self.view() {
    match rest {
      [EqualEqual, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Eq,
          expr,
          self.parse_relational(),
        )
        continue self.view()
      }
      [BangEqual, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Ne,
          expr,
          self.parse_relational(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_bitwise_and(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_equality()
  for rest = self.view() {
    match rest {
      [Amp, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::BitAnd,
          expr,
          self.parse_equality(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_bitwise_xor(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_bitwise_and()
  for rest = self.view() {
    match rest {
      [Caret, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::BitXor,
          expr,
          self.parse_bitwise_and(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_bitwise_or(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_bitwise_xor()
  for rest = self.view() {
    match rest {
      [Pipe, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::BitOr,
          expr,
          self.parse_bitwise_xor(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_logical_and(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_bitwise_or()
  for rest = self.view() {
    match rest {
      [AmpAmp, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::LogicalAnd,
          expr,
          self.parse_bitwise_or(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_logical_or(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_logical_and()
  for rest = self.view() {
    match rest {
      [PipePipe, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::LogicalOr,
          expr,
          self.parse_logical_and(),
        )
        continue self.view()
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  expr
}

///|
fn ConstEvalParser::parse_expression(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  self.parse_logical_or()
}

///|
fn ConstEvalParser::parse_binding_statement(
  self : ConstEvalParser,
) -> ConstEvalStatement raise WeslCompileError {
  let name = match self.view() {
    [Ident(name), .. rest] => {
      self.update_view(rest)
      name
    }
    _ => self.error("expected const-eval binding name")
  }
  let declared_type = match self.view() {
    [Colon, .. rest] => {
      self.update_view(rest)
      Some(self.parse_type())
    }
    _ => None
  }
  match self.view() {
    [Equal, .. rest] => self.update_view(rest)
    _ => self.error("expected `=` in const-eval binding")
  }
  let expr = self.parse_expression()
  match self.view() {
    [Semi, .. rest] => self.update_view(rest)
    _ => self.error("expected `;` after const-eval binding")
  }
  ConstEvalStatement::Binding(ConstEvalBinding::{ name, declared_type, expr })
}

///|
fn ConstEvalParser::parse_param(
  self : ConstEvalParser,
) -> ConstEvalParam raise WeslCompileError {
  let name = match self.view() {
    [Ident(name), .. rest] => {
      self.update_view(rest)
      name
    }
    _ => self.error("expected const-eval parameter name")
  }
  match self.view() {
    [Colon, .. rest] => self.update_view(rest)
    _ => self.error("expected `:` in const-eval parameter")
  }
  ConstEvalParam::{ name, declared_type: self.parse_type() }
}

///|
fn ConstEvalParser::parse_params(
  self : ConstEvalParser,
) -> Array[ConstEvalParam] raise WeslCompileError {
  match self.view() {
    [LeftParen, .. rest] => self.update_view(rest)
    _ => self.error("expected `(` in const-eval function")
  }
  let params : Array[ConstEvalParam] = []
  if self.view() is [RightParen, .. after_empty] {
    self.update_view(after_empty)
    return params
  }
  while true {
    params.push(self.parse_param())
    match self.view() {
      [Comma, RightParen, .. after_trailing] => {
        self.update_view(after_trailing)
        break
      }
      [Comma, .. after_comma] => self.update_view(after_comma)
      [RightParen, .. after_paren] => {
        self.update_view(after_paren)
        break
      }
      _ => self.error("expected `,` or `)` in const-eval parameter list")
    }
  }
  params
}

///|
fn ConstEvalParser::parse_statement(
  self : ConstEvalParser,
) -> ConstEvalStatement raise WeslCompileError {
  match self.view() {
    [Ident("let"), .. rest] => {
      self.update_view(rest)
      self.parse_binding_statement()
    }
    [Ident("var"), .. rest] => {
      self.update_view(rest)
      self.parse_binding_statement()
    }
    [Ident("return"), .. rest] => {
      self.update_view(rest)
      let expr = self.parse_expression()
      match self.view() {
        [Semi, .. after_semi] => self.update_view(after_semi)
        _ => self.error("expected `;` after const-eval return")
      }
      ConstEvalStatement::Return(expr)
    }
    _ => self.error("expected const-eval statement")
  }
}

///|
fn ConstEvalParser::parse_function(
  self : ConstEvalParser,
) -> ConstEvalFunction raise WeslCompileError {
  let mut has_const = false
  for rest = self.view() {
    match rest {
      [At, Ident(name), .. next] => {
        if name == "const" {
          has_const = true
        }
        continue next
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  if !has_const {
    raise WeslCompileError::Validation("expected `@const` function")
  }
  match self.view() {
    [Ident("fn"), .. rest] => self.update_view(rest)
    _ => self.error("expected `fn` in const-eval source")
  }
  let name = match self.view() {
    [Ident(name), .. rest] => {
      self.update_view(rest)
      name
    }
    _ => self.error("expected const-eval function name")
  }
  let params = self.parse_params()
  match self.view() {
    [Arrow, .. rest] => self.update_view(rest)
    _ => self.error("expected `->` in const-eval function")
  }
  let return_type = self.parse_type()
  match self.view() {
    [LeftBrace, .. rest] => self.update_view(rest)
    _ => self.error("expected `{` in const-eval function")
  }
  let statements : Array[ConstEvalStatement] = []
  while !(self.view() is [RightBrace, ..]) {
    statements.push(self.parse_statement())
  }
  match self.view() {
    [RightBrace, .. rest] => self.update_view(rest)
    _ => self.error("expected `}` in const-eval function")
  }
  if !self.view().is_empty() {
    self.error("unexpected trailing const-eval tokens")
  }
  ConstEvalFunction::{ name, params, return_type, statements }
}

///|
priv enum ConstEvalValue {
  Bool(Bool)
  AbstractInt(Int64)
  AbstractFloat(Double)
  I32(Int64)
  U32(Int64)
  F32(Float)
}

///|
priv struct ConstEvalContext {
  bindings : @hashmap.HashMap[String, ConstEvalValue]
  functions : @hashmap.HashMap[String, ConstEvalFunction]
}

///|
fn ConstEvalContext::new() -> ConstEvalContext {
  ConstEvalContext::{
    bindings: @hashmap.HashMap::new(),
    functions: @hashmap.HashMap::new(),
  }
}

///|
fn const_eval_clone_bindings(
  bindings : @hashmap.HashMap[String, ConstEvalValue],
) -> @hashmap.HashMap[String, ConstEvalValue] {
  let copy : @hashmap.HashMap[String, ConstEvalValue] = @hashmap.HashMap::new()
  for entry in bindings.iter() {
    let (name, value) = entry
    copy.set(name, value)
  }
  copy
}

///|
fn ConstEvalContext::new_call_scope(
  self : ConstEvalContext,
) -> ConstEvalContext {
  ConstEvalContext::{
    bindings: const_eval_clone_bindings(self.bindings),
    functions: self.functions,
  }
}

///|
fn ConstEvalValue::value_type(self : ConstEvalValue) -> ConstEvalType {
  match self {
    Bool(_) => ConstEvalType::Bool
    AbstractInt(_) => ConstEvalType::AbstractInt
    AbstractFloat(_) => ConstEvalType::AbstractFloat
    I32(_) => ConstEvalType::I32
    U32(_) => ConstEvalType::U32
    F32(_) => ConstEvalType::F32
  }
}

///|
fn ConstEvalType::label(self : ConstEvalType) -> String {
  match self {
    AbstractInt => "AbstractInt"
    AbstractFloat => "AbstractFloat"
    Bool => "bool"
    I32 => "i32"
    U32 => "u32"
    F32 => "f32"
  }
}

///|
fn ConstEvalBinaryOp::symbol(self : ConstEvalBinaryOp) -> String {
  match self {
    Add => "+"
    Sub => "-"
    Mul => "*"
    Div => "/"
    Mod => "%"
    Eq => "=="
    Ne => "!="
    Lt => "<"
    Le => "<="
    Gt => ">"
    Ge => ">="
    Shl => "<<"
    Shr => ">>"
    BitAnd => "&"
    BitOr => "|"
    BitXor => "^"
    LogicalAnd => "&&"
    LogicalOr => "||"
  }
}

///|
fn const_eval_remove_underscores(text : String) -> String {
  let parts : Array[String] = []
  for i = 0; i < text.length(); i = i + 1 {
    if text.code_unit_at(i).to_int() != 95 {
      parts.push(text[i:i + 1].to_owned())
    }
  }
  parts.join("")
}

///|
fn const_eval_is_hex_digit(code : Int) -> Bool {
  const_eval_is_digit(code) ||
  (code >= 65 && code <= 70) ||
  (code >= 97 && code <= 102)
}

///|
fn const_eval_hex_digit_value(code : Int) -> Int raise WeslCompileError {
  if const_eval_is_digit(code) {
    return code - 48
  }
  if code >= 65 && code <= 70 {
    return code - 55
  }
  if code >= 97 && code <= 102 {
    return code - 87
  }
  raise WeslCompileError::Validation("invalid hex digit")
}

///|
fn const_eval_parse_integer_literal(
  text : String,
) -> Int64 raise WeslCompileError {
  let normalized = const_eval_remove_underscores(text)
  if normalized.length() >= 2 &&
    (normalized[:2].to_owned() == "0x" || normalized[:2].to_owned() == "0X") {
    let digits = normalized[2:normalized.length()].to_owned()
    return @string.parse_int64(digits[:], base=16) catch {
      _ =>
        raise WeslCompileError::Validation("invalid integer literal `\{text}`")
    }
  }
  @string.parse_int64(normalized[:], base=10) catch {
    _ => raise WeslCompileError::Validation("invalid integer literal `\{text}`")
  }
}

///|
fn const_eval_parse_hex_float_literal(
  text : String,
) -> Double raise WeslCompileError {
  let normalized = const_eval_remove_underscores(text)
  guard normalized.length() >= 3 &&
    (normalized[:2].to_owned() == "0x" || normalized[:2].to_owned() == "0X") else {
    raise WeslCompileError::Validation("invalid float literal `\{text}`")
  }
  let body = normalized[2:normalized.length()].to_owned()
  let exponent_index = match body.find("p") {
    Some(index) => index
    None =>
      match body.find("P") {
        Some(index) => index
        None =>
          raise WeslCompileError::Validation("invalid float literal `\{text}`")
      }
  }
  let mantissa = body[:exponent_index].to_owned()
  let exponent = @string.parse_int(
    body[exponent_index + 1:body.length()],
    base=10,
  ) catch {
    _ => raise WeslCompileError::Validation("invalid float literal `\{text}`")
  }
  let dot_index = mantissa.find(".")
  let integer_text = match dot_index {
    Some(index) => mantissa[:index].to_owned()
    None => mantissa
  }
  let fraction_text = match dot_index {
    Some(index) => mantissa[index + 1:mantissa.length()].to_owned()
    None => ""
  }
  let mut value = if integer_text == "" {
    0.0
  } else {
    const_eval_parse_integer_literal("0x\{integer_text}").to_double()
  }
  let mut factor = 1.0 / 16.0
  for i = 0; i < fraction_text.length(); i = i + 1 {
    let code = fraction_text.code_unit_at(i).to_int()
    if !const_eval_is_hex_digit(code) {
      raise WeslCompileError::Validation("invalid float literal `\{text}`")
    }
    value = value + const_eval_hex_digit_value(code).to_double() * factor
    factor = factor / 16.0
  }
  if exponent >= 0 {
    for _ in 0..<exponent {
      value = value * 2.0
    }
  } else {
    for _ in 0..<-exponent {
      value = value / 2.0
    }
  }
  value
}

///|
fn const_eval_parse_double_literal(
  text : String,
) -> Double raise WeslCompileError {
  let normalized = const_eval_remove_underscores(text)
  let parsed = try? @string.parse_double(normalized[:])
  match parsed {
    Ok(value) => value
    Err(_) =>
      if normalized.length() >= 2 &&
        (normalized[:2].to_owned() == "0x" || normalized[:2].to_owned() == "0X") {
        const_eval_parse_hex_float_literal(normalized)
      } else {
        raise WeslCompileError::Validation("invalid float literal `\{text}`")
      }
  }
}

///|
fn const_eval_exact_f32_from_double(
  text : String,
  value : Double,
) -> Float raise WeslCompileError {
  let narrowed = Float::from_double(value)
  if Float::is_inf(narrowed) || Float::is_nan(narrowed) {
    raise WeslCompileError::Validation("f32 literal out of range `\{text}`")
  }
  if narrowed.to_double() != value {
    raise WeslCompileError::Validation("f32 literal loses precision `\{text}`")
  }
  narrowed
}

///|
fn const_eval_parse_literal(
  text : String,
) -> ConstEvalValue raise WeslCompileError {
  if text.length() == 0 {
    raise WeslCompileError::Validation("empty literal")
  }
  match text {
    "true" => return ConstEvalValue::Bool(true)
    "false" => return ConstEvalValue::Bool(false)
    _ => ()
  }
  let is_hex = text.length() >= 2 &&
    (text[:2].to_owned() == "0x" || text[:2].to_owned() == "0X")
  if text.contains(".") || text.contains("p") || text.contains("P") {
    let float_text = match text[text.length() - 1:text.length()].to_owned() {
      "f" => text[:text.length() - 1].to_owned()
      _ => text
    }
    let value = const_eval_parse_double_literal(float_text)
    return match text[text.length() - 1:text.length()].to_owned() {
      "f" => ConstEvalValue::F32(const_eval_exact_f32_from_double(text, value))
      _ => ConstEvalValue::AbstractFloat(value)
    }
  }
  if is_hex {
    return ConstEvalValue::AbstractInt(const_eval_parse_integer_literal(text))
  }
  let suffix = text[text.length() - 1:text.length()].to_owned()
  match suffix {
    "u" =>
      ConstEvalValue::U32(
        const_eval_require_u32(
          ConstEvalValue::AbstractInt(
            const_eval_parse_integer_literal(
              text[:text.length() - 1].to_owned(),
            ),
          ),
          text,
        ),
      )
    "i" =>
      ConstEvalValue::I32(
        const_eval_require_i32(
          ConstEvalValue::AbstractInt(
            const_eval_parse_integer_literal(
              text[:text.length() - 1].to_owned(),
            ),
          ),
          text,
        ),
      )
    "f" => {
      let value = const_eval_parse_double_literal(
        text[:text.length() - 1].to_owned(),
      )
      ConstEvalValue::F32(const_eval_exact_f32_from_double(text, value))
    }
    _ => ConstEvalValue::AbstractInt(const_eval_parse_integer_literal(text))
  }
}

///|
fn const_eval_require_i32(
  value : ConstEvalValue,
  context : String,
) -> Int64 raise WeslCompileError {
  match value {
    Bool(_) =>
      raise WeslCompileError::Validation(
        "cannot convert bool to i32 in \{context}",
      )
    AbstractInt(number) =>
      if number < CONST_EVAL_I32_MIN || number > CONST_EVAL_I32_MAX {
        raise WeslCompileError::Validation(
          "value out of range for i32 in \{context}",
        )
      } else {
        number
      }
    I32(number) => number
    U32(number) =>
      if number > CONST_EVAL_I32_MAX {
        raise WeslCompileError::Validation(
          "value out of range for i32 in \{context}",
        )
      } else {
        number
      }
    AbstractFloat(_) =>
      raise WeslCompileError::Validation(
        "cannot convert abstract float to i32 in \{context}",
      )
    F32(_) =>
      raise WeslCompileError::Validation(
        "cannot convert f32 to i32 in \{context}",
      )
  }
}

///|
fn const_eval_require_u32(
  value : ConstEvalValue,
  context : String,
) -> Int64 raise WeslCompileError {
  match value {
    Bool(_) =>
      raise WeslCompileError::Validation(
        "cannot convert bool to u32 in \{context}",
      )
    AbstractInt(number) =>
      if number < 0 || number > CONST_EVAL_U32_MAX {
        raise WeslCompileError::Validation(
          "value out of range for u32 in \{context}",
        )
      } else {
        number
      }
    U32(number) => number
    I32(number) =>
      if number < 0 {
        raise WeslCompileError::Validation(
          "value out of range for u32 in \{context}",
        )
      } else {
        number
      }
    AbstractFloat(_) =>
      raise WeslCompileError::Validation(
        "cannot convert abstract float to u32 in \{context}",
      )
    F32(_) =>
      raise WeslCompileError::Validation(
        "cannot convert f32 to u32 in \{context}",
      )
  }
}

///|
fn const_eval_require_f32(
  value : ConstEvalValue,
  context : String,
) -> Float raise WeslCompileError {
  match value {
    Bool(_) =>
      raise WeslCompileError::Validation(
        "cannot convert bool to f32 in \{context}",
      )
    AbstractInt(number) =>
      const_eval_exact_f32_from_double(context, number.to_double())
    AbstractFloat(number) => const_eval_exact_f32_from_double(context, number)
    F32(number) => number
    I32(_) =>
      raise WeslCompileError::Validation(
        "cannot convert i32 to f32 in \{context}",
      )
    U32(_) =>
      raise WeslCompileError::Validation(
        "cannot convert u32 to f32 in \{context}",
      )
  }
}

///|
fn const_eval_require_bool(
  value : ConstEvalValue,
  context : String,
) -> Bool raise WeslCompileError {
  match value {
    Bool(value) => value
    _ =>
      raise WeslCompileError::Validation(
        "cannot convert non-bool to bool in \{context}",
      )
  }
}

///|
fn const_eval_require_abstract_int(
  value : ConstEvalValue,
  context : String,
) -> Int64 raise WeslCompileError {
  match value {
    AbstractInt(number) => number
    _ =>
      raise WeslCompileError::Validation(
        "cannot convert non-abstract-int to abstract int in \{context}",
      )
  }
}

///|
fn const_eval_convert_to_type(
  value : ConstEvalValue,
  target : ConstEvalType,
  context : String,
) -> ConstEvalValue raise WeslCompileError {
  match target {
    AbstractInt => value
    AbstractFloat => value
    Bool => ConstEvalValue::Bool(const_eval_require_bool(value, context))
    I32 => ConstEvalValue::I32(const_eval_require_i32(value, context))
    U32 => ConstEvalValue::U32(const_eval_require_u32(value, context))
    F32 => ConstEvalValue::F32(const_eval_require_f32(value, context))
  }
}

///|
fn const_eval_unary_neg(
  value : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  match value {
    Bool(_) => raise WeslCompileError::Validation("cannot negate bool literal")
    AbstractInt(number) => ConstEvalValue::AbstractInt(-number)
    AbstractFloat(number) => ConstEvalValue::AbstractFloat(-number)
    I32(number) => ConstEvalValue::I32(-number)
    U32(_) => raise WeslCompileError::Validation("cannot negate u32 literal")
    F32(number) => ConstEvalValue::F32(-number)
  }
}

///|
fn const_eval_unary_not(
  value : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  ConstEvalValue::Bool(!const_eval_require_bool(value, "logical not"))
}

///|
fn const_eval_unary_bit_not(
  value : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  match value {
    Bool(_) =>
      raise WeslCompileError::Validation(
        "cannot use unary operator `~` on type `bool`",
      )
    AbstractInt(number) => ConstEvalValue::AbstractInt(number.lnot())
    I32(number) =>
      ConstEvalValue::I32(
        const_eval_require_i32(
          ConstEvalValue::AbstractInt(number.lnot()),
          "bitwise complement",
        ),
      )
    U32(number) => ConstEvalValue::U32(CONST_EVAL_U32_MAX - number)
    AbstractFloat(_) =>
      raise WeslCompileError::Validation(
        "cannot use unary operator `~` on type `AbstractFloat`",
      )
    F32(_) =>
      raise WeslCompileError::Validation(
        "cannot use unary operator `~` on type `f32`",
      )
  }
}

///|
fn const_eval_to_abstract_float(
  value : ConstEvalValue,
  context : String,
) -> Double raise WeslCompileError {
  match value {
    Bool(_) =>
      raise WeslCompileError::Validation(
        "cannot use bool with abstract float in \{context}",
      )
    AbstractInt(number) => number.to_double()
    AbstractFloat(number) => number
    F32(number) => number.to_double()
    I32(_) =>
      raise WeslCompileError::Validation(
        "cannot use i32 with abstract float in \{context}",
      )
    U32(_) =>
      raise WeslCompileError::Validation(
        "cannot use u32 with abstract float in \{context}",
      )
  }
}

///|
fn const_eval_binary_int(
  op : ConstEvalBinaryOp,
  lhs : Int64,
  rhs : Int64,
) -> Int64 raise WeslCompileError {
  match op {
    Add => lhs + rhs
    Sub => lhs - rhs
    Mul => lhs * rhs
    Div => lhs / rhs
    Mod => lhs % rhs
    _ =>
      raise WeslCompileError::Validation(
        "unsupported integer arithmetic operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_binary_float(
  op : ConstEvalBinaryOp,
  lhs : Float,
  rhs : Float,
) -> Float raise WeslCompileError {
  match op {
    Add => lhs + rhs
    Sub => lhs - rhs
    Mul => lhs * rhs
    Div => lhs / rhs
    Mod => lhs - (lhs / rhs).trunc() * rhs
    _ =>
      raise WeslCompileError::Validation(
        "unsupported f32 arithmetic operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_binary_abstract_float(
  op : ConstEvalBinaryOp,
  lhs : Double,
  rhs : Double,
) -> Double raise WeslCompileError {
  match op {
    Add => lhs + rhs
    Sub => lhs - rhs
    Mul => lhs * rhs
    Div => lhs / rhs
    Mod => lhs - (lhs / rhs).trunc() * rhs
    _ =>
      raise WeslCompileError::Validation(
        "unsupported abstract float arithmetic operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_bitwise_int(
  op : ConstEvalBinaryOp,
  lhs : Int64,
  rhs : Int64,
) -> Int64 raise WeslCompileError {
  match op {
    BitAnd => lhs & rhs
    BitOr => lhs | rhs
    BitXor => lhs ^ rhs
    _ =>
      raise WeslCompileError::Validation(
        "unsupported integer bitwise operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_shift_count(
  value : ConstEvalValue,
  context : String,
) -> Int raise WeslCompileError {
  let count = const_eval_require_u32(value, context)
  if count >= 64 {
    raise WeslCompileError::Validation("shift count out of range in \{context}")
  }
  count.to_int()
}

///|
fn const_eval_shift_int(
  op : ConstEvalBinaryOp,
  lhs : Int64,
  rhs : ConstEvalValue,
) -> Int64 raise WeslCompileError {
  let count = const_eval_shift_count(rhs, "shift expression")
  match op {
    Shl => lhs << count
    Shr => lhs >> count
    _ =>
      raise WeslCompileError::Validation(
        "unsupported shift operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_bool_order(value : Bool) -> Int {
  if value {
    1
  } else {
    0
  }
}

///|
fn const_eval_compare_int(
  op : ConstEvalBinaryOp,
  lhs : Int64,
  rhs : Int64,
) -> Bool raise WeslCompileError {
  match op {
    Eq => lhs == rhs
    Ne => lhs != rhs
    Lt => lhs < rhs
    Le => lhs <= rhs
    Gt => lhs > rhs
    Ge => lhs >= rhs
    _ =>
      raise WeslCompileError::Validation(
        "unsupported comparison operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_compare_float(
  op : ConstEvalBinaryOp,
  lhs : Double,
  rhs : Double,
) -> Bool raise WeslCompileError {
  match op {
    Eq => lhs == rhs
    Ne => lhs != rhs
    Lt => lhs < rhs
    Le => lhs <= rhs
    Gt => lhs > rhs
    Ge => lhs >= rhs
    _ =>
      raise WeslCompileError::Validation(
        "unsupported comparison operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_compare_bool(
  op : ConstEvalBinaryOp,
  lhs : Bool,
  rhs : Bool,
) -> Bool raise WeslCompileError {
  let left = const_eval_bool_order(lhs)
  let right = const_eval_bool_order(rhs)
  match op {
    Eq => lhs == rhs
    Ne => lhs != rhs
    Lt => left < right
    Le => left <= right
    Gt => left > right
    Ge => left >= right
    _ =>
      raise WeslCompileError::Validation(
        "unsupported comparison operator `\{op.symbol()}`",
      )
  }
}

///|
fn const_eval_binary_type_error(
  op : ConstEvalBinaryOp,
  lhs : ConstEvalValue,
  rhs : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  raise WeslCompileError::Validation(
    "cannot use binary operator `\{op.symbol()}` with operands `\{lhs.value_type().label()}` and `\{rhs.value_type().label()}`",
  )
}

///|
fn const_eval_apply_bitwise(
  op : ConstEvalBinaryOp,
  lhs : ConstEvalValue,
  rhs : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  match (lhs, rhs) {
    (Bool(left), Bool(right)) =>
      match op {
        BitAnd => ConstEvalValue::Bool(left && right)
        BitOr => ConstEvalValue::Bool(left || right)
        _ => const_eval_binary_type_error(op, lhs, rhs)
      }
    (Bool(_), right) => const_eval_binary_type_error(op, lhs, right)
    (left, Bool(_)) => const_eval_binary_type_error(op, left, rhs)
    (AbstractFloat(_), right) => const_eval_binary_type_error(op, lhs, right)
    (left, AbstractFloat(_)) => const_eval_binary_type_error(op, left, rhs)
    (F32(_), right) => const_eval_binary_type_error(op, lhs, right)
    (left, F32(_)) => const_eval_binary_type_error(op, left, rhs)
    (U32(_), I32(_)) => const_eval_binary_type_error(op, lhs, rhs)
    (I32(_), U32(_)) => const_eval_binary_type_error(op, lhs, rhs)
    (U32(left), right) => {
      let value = const_eval_bitwise_int(
        op,
        left,
        const_eval_require_u32(right, "bitwise expression"),
      )
      ConstEvalValue::U32(
        const_eval_require_u32(
          ConstEvalValue::AbstractInt(value),
          "bitwise expression",
        ),
      )
    }
    (left, U32(right)) => {
      let value = const_eval_bitwise_int(
        op,
        const_eval_require_u32(left, "bitwise expression"),
        right,
      )
      ConstEvalValue::U32(
        const_eval_require_u32(
          ConstEvalValue::AbstractInt(value),
          "bitwise expression",
        ),
      )
    }
    (I32(left), right) => {
      let value = const_eval_bitwise_int(
        op,
        left,
        const_eval_require_i32(right, "bitwise expression"),
      )
      ConstEvalValue::I32(
        const_eval_require_i32(
          ConstEvalValue::AbstractInt(value),
          "bitwise expression",
        ),
      )
    }
    (left, I32(right)) => {
      let value = const_eval_bitwise_int(
        op,
        const_eval_require_i32(left, "bitwise expression"),
        right,
      )
      ConstEvalValue::I32(
        const_eval_require_i32(
          ConstEvalValue::AbstractInt(value),
          "bitwise expression",
        ),
      )
    }
    (AbstractInt(left), AbstractInt(right)) =>
      ConstEvalValue::AbstractInt(const_eval_bitwise_int(op, left, right))
  }
}

///|
fn const_eval_apply_shift(
  op : ConstEvalBinaryOp,
  lhs : ConstEvalValue,
  rhs : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  match lhs {
    Bool(_) => const_eval_binary_type_error(op, lhs, rhs)
    AbstractFloat(_) => const_eval_binary_type_error(op, lhs, rhs)
    F32(_) => const_eval_binary_type_error(op, lhs, rhs)
    AbstractInt(left) =>
      ConstEvalValue::AbstractInt(const_eval_shift_int(op, left, rhs))
    U32(left) =>
      ConstEvalValue::U32(
        const_eval_require_u32(
          ConstEvalValue::AbstractInt(const_eval_shift_int(op, left, rhs)),
          "shift expression",
        ),
      )
    I32(left) =>
      ConstEvalValue::I32(
        const_eval_require_i32(
          ConstEvalValue::AbstractInt(const_eval_shift_int(op, left, rhs)),
          "shift expression",
        ),
      )
  }
}

///|
fn const_eval_apply_comparison(
  op : ConstEvalBinaryOp,
  lhs : ConstEvalValue,
  rhs : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  match (lhs, rhs) {
    (Bool(left), Bool(right)) =>
      ConstEvalValue::Bool(const_eval_compare_bool(op, left, right))
    (Bool(_), right) => const_eval_binary_type_error(op, lhs, right)
    (left, Bool(_)) => const_eval_binary_type_error(op, left, rhs)
    (F32(left), right) =>
      ConstEvalValue::Bool(
        const_eval_compare_float(
          op,
          left.to_double(),
          const_eval_require_f32(right, "binary expression").to_double(),
        ),
      )
    (left, F32(right)) =>
      ConstEvalValue::Bool(
        const_eval_compare_float(
          op,
          const_eval_require_f32(left, "binary expression").to_double(),
          right.to_double(),
        ),
      )
    (AbstractFloat(left), right) =>
      ConstEvalValue::Bool(
        const_eval_compare_float(
          op,
          left,
          const_eval_to_abstract_float(right, "binary expression"),
        ),
      )
    (left, AbstractFloat(right)) =>
      ConstEvalValue::Bool(
        const_eval_compare_float(
          op,
          const_eval_to_abstract_float(left, "binary expression"),
          right,
        ),
      )
    (U32(_), I32(_)) => const_eval_binary_type_error(op, lhs, rhs)
    (I32(_), U32(_)) => const_eval_binary_type_error(op, lhs, rhs)
    (U32(left), right) =>
      ConstEvalValue::Bool(
        const_eval_compare_int(
          op,
          left,
          const_eval_require_u32(right, "binary expression"),
        ),
      )
    (left, U32(right)) =>
      ConstEvalValue::Bool(
        const_eval_compare_int(
          op,
          const_eval_require_u32(left, "binary expression"),
          right,
        ),
      )
    (I32(left), right) =>
      ConstEvalValue::Bool(
        const_eval_compare_int(
          op,
          left,
          const_eval_require_i32(right, "binary expression"),
        ),
      )
    (left, I32(right)) =>
      ConstEvalValue::Bool(
        const_eval_compare_int(
          op,
          const_eval_require_i32(left, "binary expression"),
          right,
        ),
      )
    (AbstractInt(left), AbstractInt(right)) =>
      ConstEvalValue::Bool(const_eval_compare_int(op, left, right))
  }
}

///|
fn const_eval_apply_binary(
  op : ConstEvalBinaryOp,
  lhs : ConstEvalValue,
  rhs : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  match op {
    Eq | Ne | Lt | Le | Gt | Ge =>
      return const_eval_apply_comparison(op, lhs, rhs)
    Shl | Shr => return const_eval_apply_shift(op, lhs, rhs)
    BitAnd | BitOr | BitXor => return const_eval_apply_bitwise(op, lhs, rhs)
    LogicalAnd | LogicalOr => return const_eval_binary_type_error(op, lhs, rhs)
    _ => ()
  }
  match (lhs, rhs) {
    (Bool(_), _) =>
      raise WeslCompileError::Validation(
        "cannot use bool in arithmetic expression",
      )
    (_, Bool(_)) =>
      raise WeslCompileError::Validation(
        "cannot use bool in arithmetic expression",
      )
    (F32(left), right) =>
      ConstEvalValue::F32(
        const_eval_binary_float(
          op,
          left,
          const_eval_require_f32(right, "binary expression"),
        ),
      )
    (left, F32(right)) =>
      ConstEvalValue::F32(
        const_eval_binary_float(
          op,
          const_eval_require_f32(left, "binary expression"),
          right,
        ),
      )
    (AbstractFloat(left), right) =>
      ConstEvalValue::AbstractFloat(
        const_eval_binary_abstract_float(
          op,
          left,
          const_eval_to_abstract_float(right, "binary expression"),
        ),
      )
    (left, AbstractFloat(right)) =>
      ConstEvalValue::AbstractFloat(
        const_eval_binary_abstract_float(
          op,
          const_eval_to_abstract_float(left, "binary expression"),
          right,
        ),
      )
    (U32(_), I32(_)) =>
      raise WeslCompileError::Validation("cannot mix i32 and u32")
    (I32(_), U32(_)) =>
      raise WeslCompileError::Validation("cannot mix i32 and u32")
    (U32(left), right) => {
      let value = const_eval_binary_int(
        op,
        left,
        const_eval_require_u32(right, "binary expression"),
      )
      ConstEvalValue::U32(
        const_eval_require_u32(
          ConstEvalValue::AbstractInt(value),
          "binary expression",
        ),
      )
    }
    (left, U32(right)) => {
      let value = const_eval_binary_int(
        op,
        const_eval_require_u32(left, "binary expression"),
        right,
      )
      ConstEvalValue::U32(
        const_eval_require_u32(
          ConstEvalValue::AbstractInt(value),
          "binary expression",
        ),
      )
    }
    (I32(left), right) => {
      let value = const_eval_binary_int(
        op,
        left,
        const_eval_require_i32(right, "binary expression"),
      )
      ConstEvalValue::I32(
        const_eval_require_i32(
          ConstEvalValue::AbstractInt(value),
          "binary expression",
        ),
      )
    }
    (left, I32(right)) => {
      let value = const_eval_binary_int(
        op,
        const_eval_require_i32(left, "binary expression"),
        right,
      )
      ConstEvalValue::I32(
        const_eval_require_i32(
          ConstEvalValue::AbstractInt(value),
          "binary expression",
        ),
      )
    }
    (AbstractInt(left), AbstractInt(right)) =>
      ConstEvalValue::AbstractInt(const_eval_binary_int(op, left, right))
  }
}

///|
fn const_eval_clamp_type(
  values : Array[ConstEvalValue],
) -> ConstEvalType raise WeslCompileError {
  let mut has_f32 = false
  let mut has_abstract_float = false
  let mut has_i32 = false
  let mut has_u32 = false
  for value in values {
    match value.value_type() {
      Bool =>
        raise WeslCompileError::Validation(
          "cannot use bool with clamp arguments",
        )
      F32 => has_f32 = true
      AbstractFloat => has_abstract_float = true
      I32 => has_i32 = true
      U32 => has_u32 = true
      AbstractInt => ()
    }
  }
  if has_u32 && has_i32 {
    raise WeslCompileError::Validation("ambiguous clamp argument types")
  }
  if has_f32 {
    return ConstEvalType::F32
  }
  if has_abstract_float {
    return ConstEvalType::F32
  }
  if has_u32 {
    return ConstEvalType::U32
  }
  ConstEvalType::I32
}

///|
fn const_eval_numeric_join_type(
  values : Array[ConstEvalValue],
  context : String,
) -> ConstEvalType raise WeslCompileError {
  let mut has_f32 = false
  let mut has_abstract_float = false
  let mut has_i32 = false
  let mut has_u32 = false
  for value in values {
    match value.value_type() {
      Bool =>
        raise WeslCompileError::Validation(
          "cannot use bool with \{context} arguments",
        )
      F32 => has_f32 = true
      AbstractFloat => has_abstract_float = true
      I32 => has_i32 = true
      U32 => has_u32 = true
      AbstractInt => ()
    }
  }
  if has_u32 && has_i32 {
    raise WeslCompileError::Validation("ambiguous \{context} argument types")
  }
  if has_f32 {
    return ConstEvalType::F32
  }
  if has_abstract_float {
    return ConstEvalType::AbstractFloat
  }
  if has_u32 {
    return ConstEvalType::U32
  }
  if has_i32 {
    return ConstEvalType::I32
  }
  ConstEvalType::AbstractInt
}

///|
fn const_eval_select_join_type(
  first : ConstEvalValue,
  second : ConstEvalValue,
) -> ConstEvalType raise WeslCompileError {
  match (first.value_type(), second.value_type()) {
    (Bool, Bool) => ConstEvalType::Bool
    (Bool, _) | (_, Bool) =>
      raise WeslCompileError::Validation(
        "`select` 1st and 2nd arguments are incompatible",
      )
    _ => const_eval_numeric_join_type([first, second], "`select` 1st and 2nd")
  }
}

///|
fn const_eval_apply_clamp(
  args : Array[ConstEvalValue],
) -> ConstEvalValue raise WeslCompileError {
  if args.length() != 3 {
    raise WeslCompileError::Validation("clamp expects three arguments")
  }
  let target = const_eval_clamp_type(args)
  match target {
    F32 => {
      let value = const_eval_require_f32(args[0], "clamp")
      let min_value = const_eval_require_f32(args[1], "clamp")
      let max_value = const_eval_require_f32(args[2], "clamp")
      ConstEvalValue::F32(Float::clamp(value, min=min_value, max=max_value))
    }
    U32 => {
      let value = const_eval_require_u32(args[0], "clamp")
      let min_value = const_eval_require_u32(args[1], "clamp")
      let max_value = const_eval_require_u32(args[2], "clamp")
      ConstEvalValue::U32(Int64::clamp(value, min=min_value, max=max_value))
    }
    _ => {
      let value = const_eval_require_i32(args[0], "clamp")
      let min_value = const_eval_require_i32(args[1], "clamp")
      let max_value = const_eval_require_i32(args[2], "clamp")
      ConstEvalValue::I32(Int64::clamp(value, min=min_value, max=max_value))
    }
  }
}

///|
fn const_eval_apply_min_or_max(
  name : String,
  args : Array[ConstEvalValue],
  choose_min : Bool,
) -> ConstEvalValue raise WeslCompileError {
  if args.length() != 2 {
    raise WeslCompileError::Validation("`\{name}` expects two arguments")
  }
  let target = const_eval_numeric_join_type(args, "`\{name}`")
  match target {
    AbstractFloat => {
      let left = const_eval_to_abstract_float(args[0], name)
      let right = const_eval_to_abstract_float(args[1], name)
      ConstEvalValue::AbstractFloat(
        if choose_min {
          if left <= right {
            left
          } else {
            right
          }
        } else if left >= right {
          left
        } else {
          right
        },
      )
    }
    F32 => {
      let left = const_eval_require_f32(args[0], name)
      let right = const_eval_require_f32(args[1], name)
      ConstEvalValue::F32(
        if choose_min {
          if left <= right {
            left
          } else {
            right
          }
        } else if left >= right {
          left
        } else {
          right
        },
      )
    }
    U32 => {
      let left = const_eval_require_u32(args[0], name)
      let right = const_eval_require_u32(args[1], name)
      ConstEvalValue::U32(
        if choose_min {
          if left <= right {
            left
          } else {
            right
          }
        } else if left >= right {
          left
        } else {
          right
        },
      )
    }
    I32 => {
      let left = const_eval_require_i32(args[0], name)
      let right = const_eval_require_i32(args[1], name)
      ConstEvalValue::I32(
        if choose_min {
          if left <= right {
            left
          } else {
            right
          }
        } else if left >= right {
          left
        } else {
          right
        },
      )
    }
    AbstractInt => {
      let left = const_eval_require_abstract_int(args[0], name)
      let right = const_eval_require_abstract_int(args[1], name)
      ConstEvalValue::AbstractInt(
        if choose_min {
          if left <= right {
            left
          } else {
            right
          }
        } else if left >= right {
          left
        } else {
          right
        },
      )
    }
    Bool =>
      raise WeslCompileError::Validation(
        "cannot use bool with `\{name}` arguments",
      )
  }
}

///|
fn const_eval_abs_i64(value : Int64) -> Int64 {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn const_eval_abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn const_eval_abs_float(value : Float) -> Float {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn const_eval_apply_abs(
  args : Array[ConstEvalValue],
) -> ConstEvalValue raise WeslCompileError {
  if args.length() != 1 {
    raise WeslCompileError::Validation("`abs` expects one argument")
  }
  match args[0] {
    Bool(_) =>
      raise WeslCompileError::Validation(
        "`abs` expects a scalar or vector of scalar argument",
      )
    AbstractInt(number) =>
      ConstEvalValue::AbstractInt(const_eval_abs_i64(number))
    I32(number) => ConstEvalValue::I32(const_eval_abs_i64(number))
    U32(number) => ConstEvalValue::U32(number)
    AbstractFloat(number) =>
      ConstEvalValue::AbstractFloat(const_eval_abs_double(number))
    F32(number) => ConstEvalValue::F32(const_eval_abs_float(number))
  }
}

///|
fn const_eval_apply_select(
  args : Array[ConstEvalValue],
) -> ConstEvalValue raise WeslCompileError {
  if args.length() != 3 {
    raise WeslCompileError::Validation("`select` expects three arguments")
  }
  let condition = match args[2] {
    Bool(value) => value
    _ =>
      raise WeslCompileError::Validation(
        "`select` 3rd argument must be a boolean or vector of boolean",
      )
  }
  let target = const_eval_select_join_type(args[0], args[1])
  let chosen = if condition { args[1] } else { args[0] }
  const_eval_convert_to_type(chosen, target, "select")
}

///|
fn const_eval_apply_bool_builtin(
  name : String,
  args : Array[ConstEvalValue],
) -> ConstEvalValue raise WeslCompileError {
  if args.length() != 1 {
    raise WeslCompileError::Validation("`\{name}` expects one argument")
  }
  ConstEvalValue::Bool(const_eval_require_bool(args[0], name))
}

///|
fn const_eval_eval_expr(
  expr : ConstEvalExpr,
  ctx : ConstEvalContext,
) -> ConstEvalValue raise WeslCompileError {
  match expr {
    Literal(text) => const_eval_parse_literal(text)
    Binding(name) =>
      match ctx.bindings.get(name) {
        Some(value) => value
        None =>
          raise WeslCompileError::Validation(
            "unknown const-eval binding `\{name}`",
          )
      }
    UnaryNeg(inner) => const_eval_unary_neg(const_eval_eval_expr(inner, ctx))
    UnaryNot(inner) => const_eval_unary_not(const_eval_eval_expr(inner, ctx))
    UnaryBitNot(inner) =>
      const_eval_unary_bit_not(const_eval_eval_expr(inner, ctx))
    Binary(LogicalAnd, lhs, rhs) => {
      let left = const_eval_eval_expr(lhs, ctx)
      if !const_eval_require_bool(left, "logical and") {
        return ConstEvalValue::Bool(false)
      }
      ConstEvalValue::Bool(
        const_eval_require_bool(const_eval_eval_expr(rhs, ctx), "logical and"),
      )
    }
    Binary(LogicalOr, lhs, rhs) => {
      let left = const_eval_eval_expr(lhs, ctx)
      if const_eval_require_bool(left, "logical or") {
        return ConstEvalValue::Bool(true)
      }
      ConstEvalValue::Bool(
        const_eval_require_bool(const_eval_eval_expr(rhs, ctx), "logical or"),
      )
    }
    Binary(op, lhs, rhs) =>
      const_eval_apply_binary(
        op,
        const_eval_eval_expr(lhs, ctx),
        const_eval_eval_expr(rhs, ctx),
      )
    Call(name, args) => {
      let values : Array[ConstEvalValue] = []
      for arg in args {
        values.push(const_eval_eval_expr(arg, ctx))
      }
      match name {
        "clamp" => const_eval_apply_clamp(values)
        "min" => const_eval_apply_min_or_max("min", values, true)
        "max" => const_eval_apply_min_or_max("max", values, false)
        "abs" => const_eval_apply_abs(values)
        "select" => const_eval_apply_select(values)
        "all" => const_eval_apply_bool_builtin("all", values)
        "any" => const_eval_apply_bool_builtin("any", values)
        _ =>
          match ctx.functions.get(name) {
            Some(function_) =>
              const_eval_execute_function_value(
                function_,
                values,
                ctx.new_call_scope(),
              )
            None =>
              raise WeslCompileError::Validation(
                "unsupported const-eval call `\{name}`",
              )
          }
      }
    }
  }
}

///|
fn const_eval_format_f32(value : Float) -> String {
  let text = value.to_double().to_string()
  "\{text}f"
}

///|
fn const_eval_format_abstract_float(value : Double) -> String {
  let text = value.to_string()
  if text.contains(".") || text.contains("e") || text.contains("E") {
    text
  } else {
    "\{text}.0"
  }
}

///|
fn const_eval_render_value(value : ConstEvalValue) -> String {
  match value {
    Bool(value) => if value { "true" } else { "false" }
    AbstractInt(number) => "\{number}"
    AbstractFloat(number) => const_eval_format_abstract_float(number)
    I32(number) => "\{number}i"
    U32(number) => "\{number}u"
    F32(number) => const_eval_format_f32(number)
  }
}

///|
fn const_eval_execute_function_value(
  function : ConstEvalFunction,
  args : Array[ConstEvalValue],
  ctx : ConstEvalContext,
) -> ConstEvalValue raise WeslCompileError {
  if args.length() != function.params.length() {
    raise WeslCompileError::Validation(
      "const-eval function `\{function.name}` expects \{function.params.length()} arguments, got \{args.length()}",
    )
  }
  for index = 0; index < function.params.length(); index = index + 1 {
    let param = function.params[index]
    ctx.bindings.set(
      param.name,
      const_eval_convert_to_type(args[index], param.declared_type, param.name),
    )
  }
  for statement in function.statements {
    match statement {
      Binding(binding) => {
        let value = const_eval_eval_expr(binding.expr, ctx)
        let stored = match binding.declared_type {
          Some(target) =>
            const_eval_convert_to_type(value, target, binding.name)
          None => value
        }
        ctx.bindings.set(binding.name, stored)
      }
      Return(expr) => {
        let value = const_eval_eval_expr(expr, ctx)
        return const_eval_convert_to_type(
          value,
          function.return_type,
          function.name,
        )
      }
    }
  }
  raise WeslCompileError::Validation("const-eval function did not return")
}

///|
fn const_eval_validate_target(
  source : String,
  function_name : String,
) -> Array[ConstEvalExpr] raise WeslCompileError {
  let tokens = const_eval_lex(source)
  let parser = ConstEvalParser::new(tokens)
  let expr = parser.parse_expression()
  if !parser.view().is_empty() {
    raise WeslCompileError::Validation(
      "unsupported const-eval target `\{source}`",
    )
  }
  match expr {
    Call(name, args) if name == function_name => args
    _ =>
      raise WeslCompileError::Validation(
        "unsupported const-eval target `\{source}`",
      )
  }
}

///|
