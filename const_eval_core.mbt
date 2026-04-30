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
  Plus
  Minus
  Slash
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
      61 => {
        tokens.push(ConstEvalToken::Equal)
        index += 1
      }
      43 => {
        tokens.push(ConstEvalToken::Plus)
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
  I32
  U32
  F32
}

///|
priv enum ConstEvalExpr {
  Literal(String)
  Binding(String)
  UnaryNeg(ConstEvalExpr)
  Binary(ConstEvalBinaryOp, ConstEvalExpr, ConstEvalExpr)
  Call(String, Array[ConstEvalExpr])
}

///|
priv enum ConstEvalBinaryOp {
  Add
  Sub
  Div
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
    _ => self.parse_primary()
  }
}

///|
fn ConstEvalParser::parse_division(
  self : ConstEvalParser,
) -> ConstEvalExpr raise WeslCompileError {
  let mut expr = self.parse_unary()
  for rest = self.view() {
    match rest {
      [Slash, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Div,
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
  let mut expr = self.parse_division()
  for rest = self.view() {
    match rest {
      [Plus, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Add,
          expr,
          self.parse_division(),
        )
        continue self.view()
      }
      [Minus, .. next] => {
        self.update_view(next)
        expr = ConstEvalExpr::Binary(
          ConstEvalBinaryOp::Sub,
          expr,
          self.parse_division(),
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
  self.parse_additive()
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
    AbstractInt(_) => ConstEvalType::AbstractInt
    AbstractFloat(_) => ConstEvalType::AbstractFloat
    I32(_) => ConstEvalType::I32
    U32(_) => ConstEvalType::U32
    F32(_) => ConstEvalType::F32
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
fn const_eval_convert_to_type(
  value : ConstEvalValue,
  target : ConstEvalType,
  context : String,
) -> ConstEvalValue raise WeslCompileError {
  match target {
    AbstractInt => value
    AbstractFloat => value
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
    AbstractInt(number) => ConstEvalValue::AbstractInt(-number)
    AbstractFloat(number) => ConstEvalValue::AbstractFloat(-number)
    I32(number) => ConstEvalValue::I32(-number)
    U32(_) => raise WeslCompileError::Validation("cannot negate u32 literal")
    F32(number) => ConstEvalValue::F32(-number)
  }
}

///|
fn const_eval_to_abstract_float(
  value : ConstEvalValue,
  context : String,
) -> Double raise WeslCompileError {
  match value {
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
) -> Int64 {
  match op {
    Add => lhs + rhs
    Sub => lhs - rhs
    Div => lhs / rhs
  }
}

///|
fn const_eval_binary_float(
  op : ConstEvalBinaryOp,
  lhs : Float,
  rhs : Float,
) -> Float {
  match op {
    Add => lhs + rhs
    Sub => lhs - rhs
    Div => lhs / rhs
  }
}

///|
fn const_eval_binary_abstract_float(
  op : ConstEvalBinaryOp,
  lhs : Double,
  rhs : Double,
) -> Double {
  match op {
    Add => lhs + rhs
    Sub => lhs - rhs
    Div => lhs / rhs
  }
}

///|
fn const_eval_apply_binary(
  op : ConstEvalBinaryOp,
  lhs : ConstEvalValue,
  rhs : ConstEvalValue,
) -> ConstEvalValue raise WeslCompileError {
  match (lhs, rhs) {
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
  if text.contains(".") || text.contains("e") || text.contains("E") {
    "\{text}f"
  } else {
    "\{text}.0f"
  }
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
