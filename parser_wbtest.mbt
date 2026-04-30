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
fn parse_expression(source : String) -> Unit raise WeslCompileError {
  match @expression_parse.parse_expression_source(source) {
    @expression_parse.Parsed => ()
    @expression_parse.Failed(diagnostic) => {
      let message = match diagnostic.message {
        Some(message) => message
        None =>
          if diagnostic.incomplete {
            "incomplete expression"
          } else {
            "unsupported expression syntax"
          }
      }
      raise WeslCompileError::Parse("\{message}: `\{source}`")
    }
  }
}

///|
fn parse_type_specifier(source : String) -> Unit raise WeslCompileError {
  match @type_parse.parse_type_source(source) {
    @type_parse.Parsed => ()
    @type_parse.Failed(diagnostic) => {
      let message = match diagnostic.message {
        Some(message) => message
        None =>
          if diagnostic.incomplete {
            "incomplete type"
          } else {
            "unsupported type syntax"
          }
      }
      raise WeslCompileError::Parse("\{message}: `\{source}`")
    }
  }
}

///|
test "parser: generated expression parser handles WGSL operator and template forms" {
  let valid_cases = [
    "vec2<f32>(1.0, 2.0)", "array<vec2<f32>, 2>(vec2<f32>(1, 2), vec2(3, 4))", "a < b || c > d",
    "textureSample(t, s, uv).rgba[0]", "&buffer[index + 1u]", "foo(1, 2,)", "!(a == b) && (c != d)",
    "value--7",
  ]
  for expr in valid_cases {
    let result = try? parse_expression(expr)
    match result {
      Ok(_) => ()
      Err(err) => fail("\{expr}: \{err.message()}")
    }
  }
  let invalid_cases = [
    "07", "foo(", "vec2<f32>(", "a +", "textureSample(t,, uv)",
  ]
  for expr in invalid_cases {
    let result = try? parse_expression(expr)
    match result {
      Ok(_) => fail("\{expr}: expected parse failure")
      Err(_) => ()
    }
  }
}

///|
test "parser: generated type parser handles nested WGSL type specifiers" {
  let valid_cases = [
    "f32", "vec4<f32>", "mat4x4<f16>", "array<vec3<f32>, 4>", "array<array<f32, 2>, 3>",
    "ptr<storage, DynamicArray, read_write>", "package::shared::Payload", "foo::bar::Texture<vec2<f32>, N>",
  ]
  for ty in valid_cases {
    let result = try? parse_type_specifier(ty)
    match result {
      Ok(_) => ()
      Err(err) => fail("\{ty}: \{err.message()}")
    }
  }
  let invalid_cases = [
    "", "array<", "vec2<f32", "array<f32,, 2>", "ptr<storage,>", "foo::",
  ]
  for ty in invalid_cases {
    let result = try? parse_type_specifier(ty)
    match result {
      Ok(_) => fail("\{ty}: expected parse failure")
      Err(_) => ()
    }
  }
}

///|
test "parser: generated attribute parser preserves leading attributes" {
  let source =
    #|@group(0)
    #|@binding(textureIndex(1 + foo(2)))
    #|var color_texture: texture_2d<f32>;
    #|

  let unit = try! parse_translation_unit(
    try! parse_module_path("demo"),
    source,
    true,
  )
  debug_inspect(unit.global_declarations.length(), content="1")
  let declaration = unit.global_declarations[0]
  let expected_attributes =
    #|[
    #|  {
    #|    name: "group",
    #|    arguments: Some("0"),
    #|    span: { start_line: 1, end_line: 1 },
    #|  },
    #|  {
    #|    name: "binding",
    #|    arguments: Some("textureIndex(1 + foo(2))"),
    #|    span: { start_line: 2, end_line: 2 },
    #|  },
    #|]

  debug_inspect(declaration.attributes, content=expected_attributes)
  debug_inspect(declaration.ident(), content="Some(\"color_texture\")")
  let result = try? parse_translation_unit(
    try! parse_module_path("demo"),
    "@group(0\nvar value: i32;",
    true,
  )
  match result {
    Ok(_) => fail("expected unclosed attribute failure")
    Err(_) => ()
  }
}
