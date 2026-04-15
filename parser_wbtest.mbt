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
fn parser_is_digit(code : Int) -> Bool {
  code >= 48 && code <= 57
}

///|
fn parse_expression(source : String) -> Unit raise WeslCompileError {
  let expr = source.trim().to_string()
  if expr == "" {
    raise WeslCompileError::Parse("empty expression")
  }
  let mut index = 0
  if expr.code_unit_at(index).to_int() == 45 {
    index += 1
  }
  if index >= expr.length() ||
    !parser_is_digit(expr.code_unit_at(index).to_int()) {
    raise WeslCompileError::Parse("unsupported expression syntax: `\{expr}`")
  }
  let digit_start = index
  while index < expr.length() &&
        parser_is_digit(expr.code_unit_at(index).to_int()) {
    index += 1
  }
  let has_leading_zero = index - digit_start > 1 &&
    expr.code_unit_at(digit_start).to_int() == 48
  if index == expr.length() {
    if has_leading_zero {
      raise WeslCompileError::Parse("invalid numeric literal: `\{expr}`")
    }
    return
  }
  match expr.code_unit_at(index).to_int() {
    46 => { // '.'
      index += 1
      if index >= expr.length() ||
        !parser_is_digit(expr.code_unit_at(index).to_int()) {
        raise WeslCompileError::Parse(
          "unsupported expression syntax: `\{expr}`",
        )
      }
      while index < expr.length() &&
            parser_is_digit(expr.code_unit_at(index).to_int()) {
        index += 1
      }
      if index < expr.length() && expr.code_unit_at(index).to_int() == 102 {
        index += 1
      }
      if index != expr.length() {
        raise WeslCompileError::Parse(
          "unsupported expression syntax: `\{expr}`",
        )
      }
    }
    117 => { // 'u'
      if has_leading_zero {
        raise WeslCompileError::Parse("invalid numeric literal: `\{expr}`")
      }
      index += 1
      if index != expr.length() {
        raise WeslCompileError::Parse(
          "unsupported expression syntax: `\{expr}`",
        )
      }
    }
    _ =>
      raise WeslCompileError::Parse("unsupported expression syntax: `\{expr}`")
  }
}
