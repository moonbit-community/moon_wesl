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
fn const_eval_dispatch_builtin(
  name : String,
  values : Array[ConstEvalValue],
) -> ConstEvalValue? raise WeslCompileError {
  match name {
    "clamp" => Some(const_eval_apply_clamp(values))
    "min" => Some(const_eval_apply_min_or_max("min", values, true))
    "max" => Some(const_eval_apply_min_or_max("max", values, false))
    "abs" => Some(const_eval_apply_abs(values))
    "select" => Some(const_eval_apply_select(values))
    "all" => Some(const_eval_apply_bool_builtin("all", values))
    "any" => Some(const_eval_apply_bool_builtin("any", values))
    "floor" => Some(const_eval_apply_float_unary_builtin("floor", values))
    "ceil" => Some(const_eval_apply_float_unary_builtin("ceil", values))
    "round" => Some(const_eval_apply_float_unary_builtin("round", values))
    "trunc" => Some(const_eval_apply_float_unary_builtin("trunc", values))
    "fract" => Some(const_eval_apply_float_unary_builtin("fract", values))
    "sqrt" => Some(const_eval_apply_float_unary_builtin("sqrt", values))
    "inverseSqrt" =>
      Some(const_eval_apply_float_unary_builtin("inverseSqrt", values))
    "exp" => Some(const_eval_apply_float_unary_builtin("exp", values))
    "exp2" => Some(const_eval_apply_float_unary_builtin("exp2", values))
    "log" => Some(const_eval_apply_float_unary_builtin("log", values))
    "log2" => Some(const_eval_apply_float_unary_builtin("log2", values))
    "sin" => Some(const_eval_apply_float_unary_builtin("sin", values))
    "cos" => Some(const_eval_apply_float_unary_builtin("cos", values))
    "tan" => Some(const_eval_apply_float_unary_builtin("tan", values))
    "asin" => Some(const_eval_apply_float_unary_builtin("asin", values))
    "acos" => Some(const_eval_apply_float_unary_builtin("acos", values))
    "atan" => Some(const_eval_apply_float_unary_builtin("atan", values))
    "sinh" => Some(const_eval_apply_float_unary_builtin("sinh", values))
    "cosh" => Some(const_eval_apply_float_unary_builtin("cosh", values))
    "tanh" => Some(const_eval_apply_float_unary_builtin("tanh", values))
    "radians" => Some(const_eval_apply_float_unary_builtin("radians", values))
    "degrees" => Some(const_eval_apply_float_unary_builtin("degrees", values))
    "saturate" => Some(const_eval_apply_saturate(values))
    "pow" => Some(const_eval_apply_float_binary_builtin("pow", values))
    "atan2" => Some(const_eval_apply_float_binary_builtin("atan2", values))
    "ldexp" => Some(const_eval_apply_ldexp(values))
    "step" => Some(const_eval_apply_step(values))
    "mix" => Some(const_eval_apply_mix(values))
    "sign" => Some(const_eval_apply_sign(values))
    "countOneBits" =>
      Some(
        const_eval_apply_integer_bit_count(
          "countOneBits", values, const_eval_count_one_bits_width,
        ),
      )
    "countLeadingZeros" =>
      Some(
        const_eval_apply_integer_bit_count(
          "countLeadingZeros", values, const_eval_count_leading_zeros_width,
        ),
      )
    "countTrailingZeros" =>
      Some(
        const_eval_apply_integer_bit_count(
          "countTrailingZeros", values, const_eval_count_trailing_zeros_width,
        ),
      )
    "extractBits"
    | "firstLeadingBit"
    | "firstTrailingBit"
    | "fma"
    | "frexp"
    | "insertBits"
    | "modf"
    | "quantizeToF16"
    | "reverseBits"
    | "smoothstep" => {
      if const_eval_builtin_arity_is_valid(name, values.length()) {
        raise WeslCompileError::Validation("not implemented: `\{name}`")
      }
      let signature = const_eval_format_call_signature(name, values)
      raise WeslCompileError::Validation(
        "invalid function call signature: `\{signature}`",
      )
    }
    _ => None
  }
}

///|
fn const_eval_builtin_arity_is_valid(name : String, arity : Int) -> Bool {
  match name {
    "firstLeadingBit"
    | "firstTrailingBit"
    | "frexp"
    | "modf"
    | "quantizeToF16"
    | "reverseBits" => arity == 1
    "fma" | "smoothstep" => arity == 3
    "extractBits" | "insertBits" => arity == 4
    _ => false
  }
}
