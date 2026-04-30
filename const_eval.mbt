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
  let ctx = ConstEvalContext::new()
  let args : Array[ConstEvalValue] = []
  for
    arg in const_eval_validate_target(
      target_expr.trim().to_owned(),
      function.name,
    ) {
    args.push(const_eval_eval_expr(arg, ctx))
  }
  const_eval_render_value(
    const_eval_execute_function_value(function, args, ctx.new_call_scope()),
  )
}

///|
fn const_eval_parse_expression_value(
  source : String,
  ctx : ConstEvalContext,
) -> ConstEvalValue raise WeslCompileError {
  let tokens = const_eval_lex(source)
  let parser = ConstEvalParser::new(tokens)
  let expr = parser.parse_expression()
  if !parser.view().is_empty() {
    raise WeslCompileError::Validation(
      "unexpected trailing const-eval expression tokens",
    )
  }
  const_eval_eval_expr(expr, ctx)
}

///|
fn eval_const_expression(source : String) -> String raise WeslCompileError {
  const_eval_render_value(
    const_eval_parse_expression_value(source, ConstEvalContext::new()),
  )
}

///|
fn const_eval_parse_type_source(
  source : String,
) -> ConstEvalType raise WeslCompileError {
  let tokens = const_eval_lex(source)
  let parser = ConstEvalParser::new(tokens)
  let type_ = parser.parse_type()
  if !parser.view().is_empty() {
    raise WeslCompileError::Validation(
      "unexpected trailing const-eval type tokens",
    )
  }
  type_
}

///|
fn const_eval_function_from_source(
  source : String,
) -> ConstEvalFunction raise WeslCompileError {
  let tokens = const_eval_lex(source)
  let parser = ConstEvalParser::new(tokens)
  parser.parse_function()
}

///|
fn const_eval_context_from_translation_unit(
  unit : TranslationUnit,
) -> ConstEvalContext raise WeslCompileError {
  let ctx = ConstEvalContext::new()
  for declaration in unit.global_declarations {
    match declaration.header {
      Function(function_) =>
        if syntax_has_attribute(declaration.attributes, "const") {
          ctx.functions.set(
            function_.name,
            const_eval_function_from_source(declaration.source),
          )
        }
      _ => ()
    }
  }
  for declaration in unit.global_declarations {
    match declaration.header {
      Const(const_) =>
        match const_.initializer {
          Some(initializer) => {
            let value = const_eval_parse_expression_value(initializer, ctx)
            let stored = match const_.type_text {
              Some(type_source) =>
                const_eval_convert_to_type(
                  value,
                  const_eval_parse_type_source(type_source),
                  const_.name,
                )
              None => value
            }
            ctx.bindings.set(const_.name, stored)
          }
          None => ()
        }
      _ => ()
    }
  }
  ctx
}

///|
fn const_eval_from_translation_unit(
  unit : TranslationUnit,
  target_expr : String,
) -> String raise WeslCompileError {
  let ctx = const_eval_context_from_translation_unit(unit)
  const_eval_render_value(const_eval_parse_expression_value(target_expr, ctx))
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
