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
pub(all) struct EvalResult {
  value : String
} derive(Eq, Debug)

///|
pub fn EvalResult::to_string(self : EvalResult) -> String {
  self.value
}

///|
fn eval_const_function(
  source : String,
  target_expr : String,
) -> String raise WeslCompileError {
  let tokens = const_eval_lex(source)
  let parser = ConstEvalParser::new(tokens)
  let function = parser.parse_function()
  const_eval_validate_target(target_expr.trim().to_owned(), function.name)
  const_eval_execute_function(function)
}

///|
fn eval_const_expression(source : String) -> String raise WeslCompileError {
  let tokens = const_eval_lex(source)
  let parser = ConstEvalParser::new(tokens)
  let expr = parser.parse_expression()
  if !parser.view().is_empty() {
    raise WeslCompileError::Validation(
      "unexpected trailing const-eval expression tokens",
    )
  }
  const_eval_render_value(const_eval_eval_expr(expr, @hashmap.HashMap::new()))
}

///|
fn const_eval_target_function_name(
  target_expr : String,
) -> String raise WeslCompileError {
  let tokens = const_eval_lex(target_expr.trim().to_owned())
  let parser = ConstEvalParser::new(tokens)
  match parser.view() {
    [Ident(name), LeftParen, RightParen, .. rest] => {
      parser.update_view(rest)
      if parser.view().is_empty() {
        return name
      }
    }
    _ => ()
  }
  raise WeslCompileError::Validation(
    "unsupported const-eval target `\{target_expr}`",
  )
}

///|
fn const_eval_from_translation_unit(
  unit : TranslationUnit,
  target_expr : String,
) -> String raise WeslCompileError {
  let target_name = const_eval_target_function_name(target_expr)
  let mut found_function = false
  for declaration in unit.global_declarations {
    match declaration.header {
      Function(function_) if function_.name == target_name => {
        found_function = true
        if syntax_has_attribute(declaration.attributes, "const") {
          return eval_const_function(declaration.source, target_expr)
        }
      }
      _ => ()
    }
  }
  if found_function {
    raise WeslCompileError::Validation(
      "function `\{target_name}` is not marked @const",
    )
  }
  raise WeslCompileError::Validation(
    "unknown const-eval function `\{target_name}`",
  )
}

///|
pub fn eval_const(
  source : String,
  target_expr : String,
) -> EvalResult raise WeslCompileError {
  EvalResult::{ value: eval_const_function(source, target_expr) }
}

///|
pub fn eval_str(source : String) -> EvalResult raise WeslCompileError {
  EvalResult::{ value: eval_const_expression(source) }
}

///|
pub fn CompileResult::eval(
  self : CompileResult,
  source : String,
) -> EvalResult raise WeslCompileError {
  EvalResult::{ value: const_eval_from_translation_unit(self.syntax, source) }
}
