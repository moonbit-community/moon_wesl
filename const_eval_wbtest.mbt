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
fn eval_const_function(
  source : String,
  target_expr : String,
) -> String raise WeslCompileError {
  let tokens = const_eval_lex(source)
  let parser = ConstEvalParser::new(tokens)
  let function = parser.parse_function()
  const_eval_validate_target(target_expr.trim().to_string(), function.name)
  const_eval_execute_function(function)
}
