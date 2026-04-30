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
  let source = "@group(0)\n@binding(textureIndex(1 + foo(2)))\nvar color_texture: texture_2d<f32>;\n"

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

///|
test "parser: generated struct parser records member names and types" {
  let unit = try! parse_translation_unit(
    try! parse_module_path("demo"),
    "struct VertexOutput {\n  @builtin(position) clip_position: vec4<f32>,\n  color: array<vec3<f32>, 4>,\n  index: u32\n};\n",
    true,
  )
  match unit.global_declarations[0].header {
    Struct(header) => {
      let expected_members =
        #|[
        #|  { name: "clip_position", type_text: "vec4<f32>" },
        #|  { name: "color", type_text: "array<vec3<f32>, 4>" },
        #|  { name: "index", type_text: "u32" },
        #|]

      debug_inspect(header.members, content=expected_members)
    }
    _ => fail("expected struct declaration")
  }
}

///|
test "parser: generated function parser records signature" {
  let source =
    #|@fragment
    #|fn shade<T>(
    #|  @location(0) color: vec4<f32>,
    #|  index: array<u32, 4>,
    #|) -> @location(0) vec4<f32> {
    #|  return color;
    #|}
    #|
  let unit = try! parse_translation_unit(
    try! parse_module_path("demo"),
    source,
    true,
  )
  match unit.global_declarations[0].header {
    Function(header) => {
      debug_inspect(header.name, content="\"shade\"")
      debug_inspect(header.generic_parameters, content="Some(\"T\")")
      let expected_parameters =
        #|[
        #|  { name: "color", type_text: "vec4<f32>" },
        #|  { name: "index", type_text: "array<u32, 4>" },
        #|]

      debug_inspect(header.parameters, content=expected_parameters)
      debug_inspect(header.return_type, content="Some(\"vec4<f32>\")")
      let expected_body =
        #|[{ kind: Return, source: "return color;" }]

      debug_inspect(header.body.statements, content=expected_body)
    }
    _ => fail("expected function declaration")
  }
}

///|
test "parser: generated statement parser classifies function body statements" {
  let source =
    #|fn statements() {
    #|  var value: i32 = 0;
    #|  let limit: i32 = 4;
    #|  value += 1;
    #|  value++;
    #|  if (value > limit) { break; }
    #|  loop { continuing { break if value > 10; } }
    #|  textureStore(tex, coord, vec4<f32>());
    #|  return;
    #|}
    #|
  let unit = try! parse_translation_unit(
    try! parse_module_path("demo"),
    source,
    true,
  )
  match unit.global_declarations[0].header {
    Function(header) => {
      let kinds : Array[StatementKind] = []
      for statement in header.body.statements {
        kinds.push(statement.kind)
      }
      let expected_kinds =
        #|[Var, Let, CompoundAssignment, Increment, If, Loop, Call, Return]
      debug_inspect(kinds, content=expected_kinds)
    }
    _ => fail("expected function declaration")
  }
}

///|
test "parser: generated binding parser records type annotations and initializers" {
  let source =
    #|alias color = vec4<f32>;
    #|const scale: f32 = 2.0;
    #|override enabled: bool = true;
    #|let index: u32 = 4u;
    #|@group(0) @binding(0) var<storage, read_write> values: array<f32>;
    #|
  let unit = try! parse_translation_unit(
    try! parse_module_path("demo"),
    source,
    true,
  )
  match unit.global_declarations[0].header {
    Alias(header) => debug_inspect(header.target, content="Some(\"vec4<f32>\")")
    _ => fail("expected alias declaration")
  }
  match unit.global_declarations[1].header {
    Const(header) => {
      debug_inspect(header.type_text, content="Some(\"f32\")")
      debug_inspect(header.initializer, content="Some(\"2.0\")")
    }
    _ => fail("expected const declaration")
  }
  match unit.global_declarations[2].header {
    Override(header) => {
      debug_inspect(header.type_text, content="Some(\"bool\")")
      debug_inspect(header.initializer, content="Some(\"true\")")
    }
    _ => fail("expected override declaration")
  }
  match unit.global_declarations[3].header {
    Let(header) => {
      debug_inspect(header.type_text, content="Some(\"u32\")")
      debug_inspect(header.initializer, content="Some(\"4u\")")
    }
    _ => fail("expected let declaration")
  }
  match unit.global_declarations[4].header {
    Var(header) => {
      debug_inspect(
        header.template_arguments,
        content="Some(\"storage, read_write\")",
      )
      debug_inspect(header.type_text, content="Some(\"array<f32>\")")
      debug_inspect(header.initializer, content="None")
    }
    _ => fail("expected var declaration")
  }
}

///|
test "parser: generated directive parser records directive arguments" {
  let unit = try! parse_translation_unit(
    try! parse_module_path("demo"),
    "enable f16, chromium_experimental_full_ptr_parameters;\nrequires readonly_and_readwrite_storage_textures;\ndiagnostic(off, derivative_uniformity);\n",
    true,
  )
  match unit.global_declarations[0].header {
    EnableDirective(header) =>
      debug_inspect(
        header.names,
        content="[\"f16\", \"chromium_experimental_full_ptr_parameters\"]",
      )
    _ => fail("expected enable directive")
  }
  match unit.global_declarations[1].header {
    RequiresDirective(header) =>
      debug_inspect(
        header.names,
        content="[\"readonly_and_readwrite_storage_textures\"]",
      )
    _ => fail("expected requires directive")
  }
  match unit.global_declarations[2].header {
    DiagnosticDirective(header) =>
      debug_inspect(
        header.arguments,
        content="[\"off\", \"derivative_uniformity\"]",
      )
    _ => fail("expected diagnostic directive")
  }
}
