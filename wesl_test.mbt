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
test "wesl: module path from filesystem path follows Bevy semantics" {
  let absolute = ModulePath::from_path("/shaders/custom_material.wesl")
  let relative = ModulePath::from_path("../util.wesl")
  let package_path = ModulePath::from_path("mgstudio/shaders/util.wesl")

  debug_inspect(
    absolute.to_string(),
    content="\"package::shaders::custom_material\"",
  )
  debug_inspect(relative.to_string(), content="\"super::util\"")
  debug_inspect(package_path.to_string(), content="\"mgstudio::shaders::util\"")
}

///|
test "wesl: module path join matches relative import semantics" {
  let parent = try! parse_module_path("package::shaders")
  let child = try! parse_module_path("super::util")

  debug_inspect(
    parent.join_path(child).to_string(),
    content="\"package::util\"",
  )
}

///|
fn wesl_test_module_path_error_message(source : String) -> String {
  let path = parse_module_path(source) catch { err => return err.message() }
  ignore(path)
  abort("\{source}: expected parse failure")
}

///|
test "wesl: module path parser rejects misplaced reserved origins" {
  let valid = try! parse_module_path("super::super::util")
  debug_inspect(valid.to_string(), content="\"super::super::util\"")
  let cases = [
    ("package::self", "`self` must be a prefix of the module path"),
    ("self::super", "`super` must be a prefix of the module path"),
    ("demo::package", "`package` must be a prefix of the module path"),
    ("package::", "module name cannot be empty"),
  ]
  for case in cases {
    let (source, expected) = case
    debug_inspect(
      wesl_test_module_path_error_message(source),
      content="\"\{expected}\"",
    )
  }
}

///|
test "wesl: escape mangler matches Bevy naming" {
  let mangler = EscapeMangler::default()
  let package_path = try! parse_module_path("package::bevy_pbr::lighting")
  let slash_path = try! parse_module_path("bevy/pbr::lighting")

  debug_inspect(
    EscapeMangler::mangle(mangler, package_path, "item"),
    content="\"package__1bevy_pbr_lighting_item\"",
  )
  debug_inspect(
    EscapeMangler::mangle(mangler, slash_path, "item"),
    content="\"import_2_bevy_pbr_lighting_item\"",
  )
}

///|
test "wesl: mangler kind default is escape" {
  let path = try! parse_module_path("package::bevy_pbr::lighting")

  debug_inspect(
    ManglerKind::default().mangle(path, "item"),
    content="\"package__1bevy_pbr_lighting_item\"",
  )
}

///|
test "wesl: default result mirrors upstream empty output" {
  let result = CompileResult::default()
  let source_map = BasicSourceMap::new()
  let root_path = ModulePath::new_root()
  source_map.add_source(root_path, Some("root.wesl"), "fn helper() {}\n")
  source_map.set_default_source("fn helper() {}\n")
  source_map.add_decl("package_helper", root_path, "helper")

  debug_inspect(result.to_string(), content="\"\"")
  debug_inspect(result.has_sourcemap(), content="false")
  debug_inspect(result.modules.length(), content="0")
  debug_inspect(source_map.root.to_string(), content="\"package\"")
  debug_inspect(
    source_map.get_source(root_path),
    content="Some(\"fn helper() {}\\n\")",
  )
  debug_inspect(
    source_map.get_display_name(root_path),
    content="Some(\"root.wesl\")",
  )
  debug_inspect(
    source_map.get_default_source(),
    content="Some(\"fn helper() {}\\n\")",
  )
  debug_inspect(
    SourceMap::get_source(source_map, root_path),
    content="Some(\"fn helper() {}\\n\")",
  )
  debug_inspect(
    SourceMap::get_default_source(source_map),
    content="Some(\"fn helper() {}\\n\")",
  )
  match source_map.get_decl("package_helper") {
    Some((path, item)) => {
      debug_inspect(path.to_string(), content="\"package\"")
      debug_inspect(item, content="\"helper\"")
    }
    None => fail("expected source map declaration")
  }
}

///|
test "wesl: public const eval returns upstream literal result" {
  let result = eval_const(
    "@const fn test() -> i32 {\n  return 1 + 2;\n}", "test()",
  )
  inspect(result.to_string(), content="3i")
}

///|
test "wesl: public const eval supports typed function parameters" {
  let result = eval_const(
    "@const fn add(base: u32, extra: u32) -> u32 {\n  return base + extra;\n}", "add(40u, 2u)",
  )
  inspect(result.to_string(), content="42u")
}

///|
test "wesl: eval_str evaluates standalone const expressions" {
  inspect(eval_str("1 + 2").to_string(), content="3")
  inspect(eval_str("1u + 2u").to_string(), content="3u")
  inspect(eval_str("6u * 7u").to_string(), content="42u")
  inspect(eval_str("5 % 2").to_string(), content="1")
  inspect(eval_str("5u % 2u").to_string(), content="1u")
  inspect(eval_str("5i % 2i").to_string(), content="1i")
  inspect(eval_str("5.0 % 2.0").to_string(), content="1.0")
  inspect(eval_str("-5 % 2").to_string(), content="-1")
  inspect(eval_str("6 & 3").to_string(), content="2")
  inspect(eval_str("4 | 1").to_string(), content="5")
  inspect(eval_str("6 ^ 3").to_string(), content="5")
  inspect(eval_str("1 << 3").to_string(), content="8")
  inspect(eval_str("8 >> 1").to_string(), content="4")
  inspect(eval_str("6u & 3u").to_string(), content="2u")
  inspect(eval_str("1u << 3u").to_string(), content="8u")
  inspect(eval_str("8i >> 1u").to_string(), content="4i")
  inspect(eval_str("true & false").to_string(), content="false")
  inspect(eval_str("true | false").to_string(), content="true")
  inspect(eval_str("~0").to_string(), content="-1")
  inspect(eval_str("~0u").to_string(), content="4294967295u")
  inspect(eval_str("~0i").to_string(), content="-1i")
  inspect(eval_str("min(1, 2)").to_string(), content="1")
  inspect(eval_str("min(1, 2u)").to_string(), content="1u")
  inspect(eval_str("max(1u, 2u)").to_string(), content="2u")
  inspect(eval_str("min(1.0, 2)").to_string(), content="1.0")
  inspect(eval_str("min(1f, 2)").to_string(), content="1f")
  inspect(eval_str("abs(-3)").to_string(), content="3")
  inspect(eval_str("abs(-3i)").to_string(), content="3i")
  inspect(eval_str("abs(3u)").to_string(), content="3u")
  inspect(eval_str("abs(-3.0)").to_string(), content="3.0")
  inspect(eval_str("select(1, 2, true)").to_string(), content="2")
  inspect(eval_str("select(1, 2, false)").to_string(), content="1")
  inspect(eval_str("select(1u, 2u, true)").to_string(), content="2u")
  inspect(eval_str("select(true, false, true)").to_string(), content="false")
  inspect(eval_str("all(true)").to_string(), content="true")
  inspect(eval_str("any(false)").to_string(), content="false")
  inspect(eval_str("floor(1.9)").to_string(), content="1.0")
  inspect(eval_str("ceil(1.1)").to_string(), content="2.0")
  inspect(eval_str("round(1.5)").to_string(), content="2.0")
  inspect(eval_str("trunc(1.9)").to_string(), content="1.0")
  inspect(eval_str("fract(1.25)").to_string(), content="0.25")
  inspect(eval_str("sqrt(4.0)").to_string(), content="2.0")
  inspect(eval_str("inverseSqrt(4.0)").to_string(), content="0.5")
  inspect(eval_str("floor(1f)").to_string(), content="1f")
  inspect(eval_str("ceil(1.1f)").to_string(), content="2f")
  inspect(eval_str("round(1.5f)").to_string(), content="2f")
  inspect(eval_str("trunc(1.9f)").to_string(), content="1f")
  inspect(eval_str("fract(1.25f)").to_string(), content="0.25f")
  inspect(eval_str("sqrt(4f)").to_string(), content="2f")
  inspect(eval_str("inverseSqrt(4f)").to_string(), content="0.5f")
  inspect(eval_str("floor(1)").to_string(), content="1.0")
  inspect(eval_str("sqrt(4)").to_string(), content="2.0")
  inspect(eval_str("exp(1.0)").to_string(), content="2.718281828459045")
  inspect(eval_str("exp2(3.0)").to_string(), content="8.0")
  inspect(eval_str("log(1.0)").to_string(), content="0.0")
  inspect(eval_str("log2(8.0)").to_string(), content="3.0")
  inspect(eval_str("sin(0.0)").to_string(), content="0.0")
  inspect(eval_str("cos(0.0)").to_string(), content="1.0")
  inspect(eval_str("tan(0.0)").to_string(), content="0.0")
  inspect(eval_str("asin(0.0)").to_string(), content="0.0")
  inspect(eval_str("acos(1.0)").to_string(), content="0.0")
  inspect(eval_str("atan(1.0)").to_string(), content="0.7853981633974483")
  inspect(eval_str("sinh(0.0)").to_string(), content="0.0")
  inspect(eval_str("cosh(0.0)").to_string(), content="1.0")
  inspect(eval_str("tanh(0.0)").to_string(), content="0.0")
  inspect(eval_str("pow(2.0, 3.0)").to_string(), content="8.0")
  inspect(eval_str("atan2(1.0, 1.0)").to_string(), content="0.7853981633974483")
  inspect(eval_str("radians(180.0)").to_string(), content="3.141592653589793")
  inspect(eval_str("degrees(3.141592653589793)").to_string(), content="180.0")
  inspect(eval_str("exp(1f)").to_string(), content="2.7182817f")
  inspect(eval_str("pow(2f, 3)").to_string(), content="8f")
  inspect(eval_str("atan2(1f, 1f)").to_string(), content="0.7853982f")
  inspect(eval_str("sin(0)").to_string(), content="0.0")
  inspect(eval_str("pow(2, 3)").to_string(), content="8.0")
  inspect(eval_str("sign(-3)").to_string(), content="-1")
  inspect(eval_str("sign(-3.0)").to_string(), content="-1.0")
  inspect(eval_str("sign(0)").to_string(), content="0")
  inspect(eval_str("sign(2u)").to_string(), content="1u")
  inspect(eval_str("1.0 + 2.0").to_string(), content="3.0")
  inspect(eval_str("true").to_string(), content="true")
  inspect(eval_str("false").to_string(), content="false")
  inspect(eval_str("!true").to_string(), content="false")
  inspect(eval_str("1 == 1").to_string(), content="true")
  inspect(eval_str("1 != 2").to_string(), content="true")
  inspect(eval_str("1 < 2").to_string(), content="true")
  inspect(eval_str("2 <= 2").to_string(), content="true")
  inspect(eval_str("3 > 2").to_string(), content="true")
  inspect(eval_str("3 >= 4").to_string(), content="false")
  inspect(eval_str("true && false").to_string(), content="false")
  inspect(eval_str("true || false").to_string(), content="true")
  inspect(eval_str("(1 < 2) && !false").to_string(), content="true")
}

///|
test "wesl: compile result eval uses compiled const functions" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@const\nfn test() -> u32 {\n  let base = 40u;\n  return base + 2u;\n}\n",
  )
  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().keep_declarations(["test"]),
  )

  inspect(compiled.eval("test()").to_string(), content="42u")
}

///|
test "wesl: compile result eval sees global const context" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "const BASE: u32 = 40u;\n\n@const\nfn add_two() -> u32 {\n  return BASE + 2u;\n}\n",
  )
  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().keep_declarations(["BASE", "add_two"]),
  )

  inspect(compiled.eval("BASE + add_two()").to_string(), content="82u")
}

///|
test "wesl: compile result eval passes arguments into const functions" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "const BASE: u32 = 40u;\n\n@const\nfn add(base: u32, extra: u32) -> u32 {\n  return base + extra;\n}\n",
  )
  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().keep_declarations(["BASE", "add"]),
  )

  inspect(compiled.eval("add(BASE, 2u)").to_string(), content="42u")
}

///|
test "wesl: compile result eval handles multiplied global constants" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "const PI: f32 = 3.0;\nconst TAU: f32 = PI * 2.0;\n",
  )
  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().keep_declarations(["PI", "TAU"]),
  )

  inspect(compiled.eval("TAU").to_string(), content="6f")
}

///|
test "wesl: compile result eval handles bool global constants" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "const FLAG: bool = true;\nconst DISABLED: bool = !FLAG;\nconst HAS_SIZE: bool = 2u >= 2u;\nconst SIZE: u32 = 2u;\n",
  )
  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().keep_declarations([
      "FLAG", "DISABLED", "HAS_SIZE", "SIZE",
    ]),
  )

  inspect(compiled.eval("FLAG").to_string(), content="true")
  inspect(compiled.eval("DISABLED").to_string(), content="false")
  inspect(compiled.eval("HAS_SIZE").to_string(), content="true")
  inspect(compiled.eval("SIZE").to_string(), content="2u")
}

///|
test "wesl: feature default and bool conversion match upstream" {
  debug_inspect(Feature::default(), content="Disable")
  debug_inspect(Feature::from_bool(true), content="Enable")
  debug_inspect(Feature::from_bool(false), content="Disable")
}

///|
test "wesl: compile resolves imports and conditional translation" {
  let resolver = VirtualResolver::new()
  let util_path = ModulePath::from_path("/shaders/util")
  let root_path = ModulePath::from_path("/shaders/custom_material")
  resolver.add_module(
    util_path, "fn make_polka_dots(v: f32) -> f32 {\n  @if(PARTY_MODE) {\n    return v * 2.0;\n  } @else {\n    return v;\n  }\n}\n",
  )
  resolver.add_module(
    root_path, "import super::util::make_polka_dots;\n@fragment\nfn fragment(v: f32) -> f32 {\n  return make_polka_dots(v);\n}\n",
  )
  let options = CompileOptions::default()
    .with_lower(true)
    .with_feature("PARTY_MODE", true)
  let compiled = compile(root_path, resolver, EscapeMangler::default(), options)
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("@fragment"), content="true")
  debug_inspect(
    compiled_text.contains("package_shaders_util__2make_polka_dots"),
    content="true",
  )
  debug_inspect(compiled_text.contains("return v * 2.0;"), content="true")
}

///|
test "wesl: missing imported module stays resolver-backed" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "import super::missing::make_it;\n@fragment\nfn fragment() -> f32 {\n  return make_it();\n}\n",
  )
  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default(),
  )

  match result {
    Err(WeslCompileError::Resolve(ResolveError::ModuleNotFound(path, context))) => {
      debug_inspect(path.to_string(), content="\"package::shaders::missing\"")
      debug_inspect(context, content="\"virtual module\"")
    }
    _ => fail("expected resolver-backed missing module error")
  }
}

///|
test "wesl: lazy strip does not load unused imports" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "import super::missing::unused_helper;\n@fragment\nfn fragment() -> f32 {\n  return 1.0;\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )

  debug_inspect(compiled.to_string().contains("return 1.0;"), content="true")
}

///|
test "wesl: strip keeps entrypoints and their transitive dependencies only" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "fn helper_unused() -> f32 {\n  return 5.0;\n}\n\nfn helper_used() -> f32 {\n  return 7.0;\n}\n\n@fragment\nfn fragment() -> f32 {\n  return helper_used();\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("helper_unused"), content="false")
  debug_inspect(compiled_text.contains("helper_used"), content="true")
  debug_inspect(compiled_text.contains("fn fragment()"), content="true")
}

///|
test "wesl: strip keeps declarations referenced by attribute expressions" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "const GROUP_SIZE = 64;\n\nfn helper_unused() -> u32 {\n  return 1u;\n}\n\n@compute\n@workgroup_size(GROUP_SIZE)\nfn main() {\n  return;\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default(),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("const GROUP_SIZE"), content="true")
  debug_inspect(compiled_text.contains("helper_unused"), content="false")
  debug_inspect(
    compiled_text.contains("@workgroup_size(GROUP_SIZE)"),
    content="true",
  )
}

///|
test "wesl: lowering removes aliases and global const declarations" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "alias Scalar = f32;\nconst SCALE = 2.0;\n\nfn helper(v: Scalar) -> Scalar {\n  return v * SCALE;\n}\n\n@fragment\nfn fragment() -> f32 {\n  return helper(1.0);\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("alias Scalar"), content="false")
  debug_inspect(compiled_text.contains("const SCALE"), content="false")
  debug_inspect(compiled_text.contains("(2.0)"), content="true")
}

///|
test "wesl: grouped imports expand and local aliases resolve correctly" {
  let resolver = VirtualResolver::new()
  let util_path = ModulePath::from_path("/shaders/util")
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    util_path, "fn make_value() -> f32 {\n  return 3.0;\n}\n\nfn helper_unused() -> f32 {\n  return 5.0;\n}\n",
  )
  resolver.add_module(
    root_path, "import super::util::{make_value as renamed_value, helper_unused};\n@fragment\nfn fragment() -> f32 {\n  return renamed_value();\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(
    compiled_text.contains("return package_shaders_util__1make_value();"),
    content="true",
  )
  debug_inspect(compiled_text.contains("renamed_value"), content="false")
  debug_inspect(compiled_text.contains("helper_unused"), content="false")
}

///|
test "wesl: parse errors include module and line context" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "import super::util::make_value\n@fragment\nfn fragment() -> f32 {\n  return 1.0;\n}\n",
  )

  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )

  match result {
    Err(WeslCompileError::Parse(reason)) => {
      debug_inspect(
        reason.contains("unsupported import statement"),
        content="true",
      )
      debug_inspect(reason.contains("package::shaders::root:1"), content="true")
    }
    _ => fail("expected parse error with source context")
  }
}

///|
test "wesl: duplicate declarations include module and line context" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "fn helper() -> f32 {\n  return 1.0;\n}\n\nfn helper() -> f32 {\n  return 2.0;\n}\n",
  )

  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default(),
  )

  match result {
    Err(WeslCompileError::DuplicateSymbol(symbol)) => {
      debug_inspect(symbol.contains("helper"), content="true")
      debug_inspect(symbol.contains("package::shaders::root:5"), content="true")
    }
    _ => fail("expected duplicate symbol with source context")
  }
}

///|
test "wesl: lowering preserves non-lowered declaration kinds" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "struct Payload {\n  value: f32,\n}\n\noverride SCALE: f32 = 2.0;\n\n@fragment\nfn fragment() -> f32 {\n  return 1.0;\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true).with_strip(false),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("struct Payload"), content="true")
  debug_inspect(compiled_text.contains("override SCALE"), content="true")
}

///|
test "wesl: parser handles attribute arguments and generic var declarations" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@group(0)\n@binding(1)\nvar<uniform> DATA: f32;\n\n@fragment\nfn fragment() -> f32 {\n  return DATA;\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("@group(0)"), content="true")
  debug_inspect(compiled_text.contains("var<uniform> DATA"), content="true")
  debug_inspect(compiled_text.contains("return DATA;"), content="true")
}

///|
test "wesl: parser classifies global directives" {
  let unit = parse_translation_unit(
    ModulePath::from_path("/shaders/root"),
    "enable f16;\nrequires readonly_and_readwrite_storage_textures;\ndiagnostic(error, derivative_uniformity);\n",
    true,
  )
  let headers : Array[GlobalDeclarationHeader] = []
  for declaration in unit.global_declarations {
    headers.push(declaration.header)
  }
  let expected_headers =
    #|[
    #|  EnableDirective({ names: ["f16"] }),
    #|  RequiresDirective({ names: ["readonly_and_readwrite_storage_textures"] }),
    #|  DiagnosticDirective(
    #|    {
    #|      arguments: ["error", "derivative_uniformity"],
    #|      severity: Some("error"),
    #|      rule_name: Some("derivative_uniformity"),
    #|    },
    #|  ),
    #|]
  debug_inspect(headers, content=expected_headers)
}

///|
test "wesl: nested grouped imports resolve through syntax tree flattening" {
  let resolver = VirtualResolver::new()
  let util_path = ModulePath::from_path("/shaders/util")
  let bridge_path = ModulePath::from_path("/shaders/bridge")
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    util_path, "fn make_value() -> f32 {\n  return 3.0;\n}\n\nfn helper_unused() -> f32 {\n  return 5.0;\n}\n",
  )
  resolver.add_module(bridge_path, "fn helper() -> f32 {\n  return 7.0;\n}\n")
  resolver.add_module(
    root_path, "import super::{util::{make_value as renamed_value, helper_unused}, bridge::helper};\n@fragment\nfn fragment() -> f32 {\n  return renamed_value() + helper();\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(
    compiled_text.contains(
      "return package_shaders_util__1make_value() + package_shaders_bridge_helper();",
    ),
    content="true",
  )
  debug_inspect(compiled_text.contains("helper_unused"), content="false")
}

///|
test "wesl: published imports can be re-exported across modules" {
  let resolver = VirtualResolver::new()
  let util_path = ModulePath::from_path("/shaders/util")
  let bridge_path = ModulePath::from_path("/shaders/bridge")
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(util_path, "fn make_value() -> f32 {\n  return 3.0;\n}\n")
  resolver.add_module(bridge_path, "@publish import super::util::make_value;\n")
  resolver.add_module(
    root_path, "import super::bridge::make_value;\n@fragment\nfn fragment() -> f32 {\n  return make_value();\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(
    compiled_text.contains("package_shaders_util__1make_value"),
    content="true",
  )
  debug_inspect(
    compiled_text.contains("return package_shaders_util__1make_value();"),
    content="true",
  )
}

///|
test "wesl: private imports cannot be re-exported" {
  let resolver = VirtualResolver::new()
  let util_path = ModulePath::from_path("/shaders/util")
  let bridge_path = ModulePath::from_path("/shaders/bridge")
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(util_path, "fn make_value() -> f32 {\n  return 3.0;\n}\n")
  resolver.add_module(bridge_path, "import super::util::make_value;\n")
  resolver.add_module(
    root_path, "import super::bridge::make_value;\n@fragment\nfn fragment() -> f32 {\n  return make_value();\n}\n",
  )

  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_lower(true),
  )

  match result {
    Err(WeslCompileError::Private(item, path)) => {
      debug_inspect(item, content="\"make_value\"")
      debug_inspect(path.to_string(), content="\"package::shaders::bridge\"")
    }
    _ => fail("expected non-publish re-export to fail")
  }
}

///|
test "wesl: missing conditional feature can be configured as an error" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@if(EXPERIMENTAL_SHADER)\nfn enabled() -> f32 {\n  return 1.0;\n}\n@else\nfn disabled() -> f32 {\n  return 0.0;\n}\n",
  )

  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().set_missing_feature_behavior(Feature::Error),
  )

  match result {
    Err(WeslCompileError::InvalidExpression(message)) => {
      debug_inspect(message.contains("unexpected feature flag"), content="true")
      debug_inspect(message.contains("EXPERIMENTAL_SHADER"), content="true")
    }
    _ => fail("expected unexpected feature flag error")
  }
}

///|
test "wesl: keep conditional feature preserves unresolved attributes" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@if(EXPERIMENTAL_SHADER)\nfn enabled() -> f32 {\n  return 1.0;\n}\n@else\nfn disabled() -> f32 {\n  return 0.0;\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default()
    .with_strip(false)
    .with_validate(false)
    .set_missing_feature_behavior(Feature::Keep),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(
    compiled_text.contains("@if(EXPERIMENTAL_SHADER)"),
    content="true",
  )
  debug_inspect(compiled_text.contains("@else"), content="true")
  debug_inspect(compiled_text.contains("fn enabled()"), content="true")
  debug_inspect(compiled_text.contains("fn disabled()"), content="true")
}

///|
test "wesl: conditional expression parser rejects malformed expressions" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(root_path, "@if(true &&)\nfn bad() {}\n")
  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default(),
  )
  match result {
    Err(WeslCompileError::InvalidExpression(expr)) =>
      debug_inspect(
        expr,
        content="\"invalid if attribute expression: `true &&`\"",
      )
    _ => fail("expected invalid conditional expression")
  }
}

///|
test "wesl: conditional translation handles top-level elif chains" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@if(FIRST)\nfn selected() -> f32 {\n  return 1.0;\n}\n@elif(SECOND)\nfn selected() -> f32 {\n  return 2.0;\n}\n@else\nfn selected() -> f32 {\n  return 3.0;\n}\n\n@fragment\nfn fragment() -> f32 {\n  return selected();\n}\n",
  )

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false).with_feature("SECOND", true),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("return 1.0;"), content="false")
  debug_inspect(compiled_text.contains("return 2.0;"), content="true")
  debug_inspect(compiled_text.contains("return 3.0;"), content="false")
  debug_inspect(compiled_text.contains("@elif"), content="false")
}

///|
test "wesl: validate option controls semantic validation pass" {
  let root_path = ModulePath::from_path("/shaders/root")
  let source = "const m: mat2x2<i32> = mat2x2(1, 0, 0, 0);\n"

  let failing_resolver = VirtualResolver::new()
  failing_resolver.add_module(root_path, source)
  let failing = try? compile(
    root_path,
    failing_resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false),
  )

  match failing {
    Err(WeslCompileError::Validation(message)) =>
      debug_inspect(
        message.contains("matrix types must use floating scalar types"),
        content="true",
      )
    _ => fail("expected matrix validation error")
  }

  let passing_resolver = VirtualResolver::new()
  passing_resolver.add_module(root_path, source)
  let compiled = compile(
    root_path,
    passing_resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false).with_validate(false),
  )

  debug_inspect(compiled.to_string().contains("mat2x2<i32>"), content="true")
}

///|
test "wesl: validation checks matrix templates through AST type expressions" {
  let root_path = ModulePath::from_path("/shaders/root")
  let resolver = VirtualResolver::new()
  resolver.add_module(
    root_path, "fn main() {\n  var m: array<mat2x2<i32>, 1>;\n}\n",
  )

  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false),
  )

  match result {
    Err(WeslCompileError::Validation(message)) =>
      debug_inspect(
        message.contains("matrix types must use floating scalar types"),
        content="true",
      )
    _ => fail("expected matrix validation error")
  }
}

///|
test "wesl: validation checks matrix constructors through AST calls" {
  let root_path = ModulePath::from_path("/shaders/root")
  let resolver = VirtualResolver::new()
  resolver.add_module(root_path, "const m = mat2x2(1i, 0.0, 0.0, 0.0);\n")

  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false),
  )

  match result {
    Err(WeslCompileError::Validation(message)) =>
      debug_inspect(
        message.contains(
          "matrix constructors must not use explicit integer literals",
        ),
        content="true",
      )
    _ => fail("expected matrix constructor validation error")
  }
}

///|
test "wesl: validation checks matrix assignments through AST lhs scopes" {
  let root_path = ModulePath::from_path("/shaders/root")
  let resolver = VirtualResolver::new()
  resolver.add_module(
    root_path, "fn main() {\n  var m = mat2x2(0.0, 0.0, 0.0, 0.0);\n  m[0] = vec2(1i, 0.0);\n}\n",
  )

  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false),
  )

  match result {
    Err(WeslCompileError::Validation(message)) =>
      debug_inspect(
        message.contains(
          "matrix assignments must not use explicit integer literals",
        ),
        content="true",
      )
    _ => fail("expected matrix assignment validation error")
  }
}

///|
test "wesl: compile options expose lazy resolution control" {
  let options = CompileOptions::default()

  debug_inspect(options.lazy_resolution, content="true")
  debug_inspect(options.with_lazy(false).lazy_resolution, content="false")
}

///|
test "wesl: facade compile uses custom resolver and sourcemap option" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@compute @workgroup_size(1)\nfn main() {\n}\n",
  )

  let compiled = Wesl::new_barebones()
    .set_custom_resolver(resolver)
    .set_options(
      CompileOptions::default().with_strip(false).with_validate(false),
    )
    .use_sourcemap(true)
    .compile(root_path)

  debug_inspect(compiled.has_sourcemap(), content="true")
  debug_inspect(compiled.modules.length(), content="1")
  debug_inspect(compiled.syntax.global_declarations.length(), content="1")
  debug_inspect(compiled.to_string().contains("@compute"), content="true")
  match compiled.sourcemap {
    Some(source_map) => {
      debug_inspect(
        source_map.get_source(root_path),
        content="Some(\"@compute @workgroup_size(1)\\nfn main() {\\n}\\n\")",
      )
      debug_inspect(
        source_map.get_display_name(root_path),
        content="Some(\"package::shaders::root\")",
      )
      debug_inspect(
        source_map.get_default_source(),
        content="Some(\"@compute @workgroup_size(1)\\nfn main() {\\n}\\n\")",
      )
    }
    None => fail("expected sourcemap")
  }
}

///|
test "wesl: facade can select hash mangler" {
  let resolver = VirtualResolver::new()
  let util_path = ModulePath::from_path("/shaders/util")
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(util_path, "fn make_value() -> f32 {\n  return 3.0;\n}\n")
  resolver.add_module(
    root_path, "import super::util::make_value;\n@fragment\nfn fragment() -> f32 {\n  return make_value();\n}\n",
  )

  let compiled = Wesl::new_barebones()
    .set_custom_resolver(resolver)
    .set_options(CompileOptions::default().with_lower(true))
    .set_mangler(Hash)
    .compile(root_path)
  let compiled_text = compiled.to_string()

  debug_inspect(
    compiled_text.contains("package_shaders_util__1make_value"),
    content="false",
  )
  debug_inspect(compiled_text.contains("make_value_"), content="true")
}

///|
test "wesl: facade can set features in bulk and expose resolver" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@if(A)\nfn a() -> f32 {\n  return 1.0;\n}\n@if(B)\nfn b() -> f32 {\n  return 2.0;\n}\n@fragment\nfn fragment() -> f32 {\n  return a() + b();\n}\n",
  )

  let wesl = Wesl::new_barebones()
    .set_custom_resolver(resolver)
    .set_options(
      CompileOptions::default().with_strip(false).with_validate(false),
    )
    .set_features([("A", Feature::Enable), ("B", Feature::Enable)])
  let compiled = wesl.compile(root_path)
  let returned_resolver = wesl.resolver()

  debug_inspect(
    compiled.to_string().contains("return a() + b();"),
    content="true",
  )
  debug_inspect(returned_resolver.modules().length(), content="1")
}

///|
test "wesl: facade standard resolver can add packages and constants" {
  let root = CodegenModule::new("demo", "fn root() {}\n")
  root.add_submodule(
    CodegenModule::new(
      "shader", "@fragment\nfn fragment() -> f32 {\n  return 1.0;\n}\n",
    ),
  )
  let compiled_pkg = Wesl::new("shaders")
    .add_package(CodegenPkg::new("demo_crate", root))
    .use_stripping(false)
    .use_lower(false)
    .compile(try! parse_module_path("demo::shader"))

  debug_inspect(compiled_pkg.to_string().contains("@fragment"), content="true")

  let compiled_constants = Wesl::new("shaders")
    .add_constant("PI", 3.141592653589793)
    .use_stripping(false)
    .use_lower(false)
    .compile(try! parse_module_path("constants"))

  debug_inspect(
    compiled_constants.to_string().contains("const PI = 3.141592653589793"),
    content="true",
  )
}

///|
test "wesl: resolver exposes display name and registered modules" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(root_path, "fn helper() {}\n")

  debug_inspect(
    resolver.display_name(root_path),
    content="Some(\"package::shaders::root\")",
  )
  debug_inspect(resolver.fs_path(root_path), content="None")
  debug_inspect(resolver.modules().length(), content="1")
}

///|
test "wesl: no resolver error matches upstream context" {
  let result = try? NoResolver::new().resolve_source(ModulePath::new_root())

  match result {
    Err(ResolveError::ModuleNotFound(_, context)) =>
      debug_inspect(
        context,
        content="\"no module resolver, imports are effectively disabled here\"",
      )
    _ => fail("expected no resolver module-not-found error")
  }
}

///|
test "wesl: resolver defaults match upstream constructors" {
  let root_path = ModulePath::new_root()
  let no_resolver_result = try? NoResolver::default().resolve_source(root_path)
  let pkg_result = try? PkgResolver::default().resolve_source(
    try! parse_module_path("demo"),
  )
  let router_result = try? Router::default().resolve_source(root_path)

  debug_inspect(VirtualResolver::default().modules().length(), content="0")
  debug_inspect(
    FileResolver::default().fs_path(root_path),
    content="Some(\"package\")",
  )
  match no_resolver_result {
    Err(ResolveError::ModuleNotFound(_, context)) =>
      debug_inspect(
        context,
        content="\"no module resolver, imports are effectively disabled here\"",
      )
    _ => fail("expected default no resolver to reject modules")
  }
  match pkg_result {
    Err(ResolveError::ModuleNotFound(_, context)) =>
      debug_inspect(context, content="\"dependency `demo` not found\"")
    _ => fail("expected default package resolver to reject unknown package")
  }
  match router_result {
    Err(ResolveError::ModuleNotFound(_, context)) =>
      debug_inspect(context, content="\"no mount point\"")
    _ => fail("expected default router to have no mount point")
  }
}

///|
test "wesl: virtual resolver accepts translation units" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  let unit = parse_translation_unit(
    root_path, "fn helper() -> f32 {\n  return 1.0;\n}\n", true,
  )
  resolver.add_translation_unit(root_path, unit)

  let compiled = compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false),
  )

  debug_inspect(compiled.to_string().contains("fn helper()"), content="true")
}

///|
struct AppendDeclPreprocessor {}

///|
impl ModulePreprocessor for AppendDeclPreprocessor with preprocess_module(
  _self,
  _path,
  unit,
) {
  unit.global_declarations.push(GlobalDeclaration::{
    header: GlobalDeclarationHeader::Function(FunctionDeclaration::{
      name: "injected",
      generic_parameters: None,
      parameters: [],
      return_type: Some("f32"),
      return_type_expr: Some(TypeExpression::{
        path: [],
        ident: "f32",
        template_text: None,
        template_args: [],
      }),
      return_attributes: [],
      body: FunctionBody::{ statements: [] },
    }),
    attributes: Array::new(),
    source: "fn injected() -> f32 {\n  return 1.0;\n}",
    span: SyntaxSpan::{ start_line: 1, end_line: 3 },
  })
  unit
}

///|
struct ConditionalAppendPreprocessor {}

///|
impl ModulePreprocessor for ConditionalAppendPreprocessor with preprocess_module(
  _self,
  _path,
  unit,
) {
  unit.global_declarations.push(GlobalDeclaration::{
    header: GlobalDeclarationHeader::Function(FunctionDeclaration::{
      name: "injected",
      generic_parameters: None,
      parameters: [],
      return_type: Some("f32"),
      return_type_expr: Some(TypeExpression::{
        path: [],
        ident: "f32",
        template_text: None,
        template_args: [],
      }),
      return_attributes: [],
      body: FunctionBody::{ statements: [] },
    }),
    attributes: [
      Attribute::{
        name: "if",
        arguments: Some("EXTRA"),
        argument_exprs: [],
        condition_expr: Some(Feature("EXTRA")),
        span: SyntaxSpan::{ start_line: 1, end_line: 1 },
      },
    ],
    source: "@if(EXTRA)\nfn injected() -> f32 {\n  return 4.0;\n}",
    span: SyntaxSpan::{ start_line: 1, end_line: 4 },
  })
  unit
}

///|
test "wesl: preprocessor can transform resolved translation units" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@fragment\nfn fragment() -> f32 {\n  return injected();\n}\n",
  )

  let compiled = compile(
    root_path,
    Preprocessor::new(resolver, AppendDeclPreprocessor::{  }),
    EscapeMangler::default(),
    CompileOptions::default().with_condcomp(false).with_strip(false),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("fn injected()"), content="true")
  debug_inspect(compiled_text.contains("return injected();"), content="true")
}

///|
test "wesl: conditional translation runs after custom module preprocessing" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "@fragment\nfn fragment() -> f32 {\n  return injected();\n}\n",
  )

  let compiled = compile(
    root_path,
    Preprocessor::new(resolver, ConditionalAppendPreprocessor::{  }),
    EscapeMangler::default(),
    CompileOptions::default().with_strip(false).with_feature("EXTRA", true),
  )
  let compiled_text = compiled.to_string()

  debug_inspect(compiled_text.contains("@if(EXTRA)"), content="false")
  debug_inspect(compiled_text.contains("return 4.0;"), content="true")
}

///|
test "wesl: file resolver maps module path to wesl path" {
  let resolver = FileResolver::new("shaders")
  let root_path = ModulePath::from_path("/materials/root")

  debug_inspect(
    resolver.fs_path(root_path),
    content="Some(\"shaders/materials/root.wesl\")",
  )
  let wgsl_resolver = resolver.set_extension("wgsl")
  debug_inspect(
    wgsl_resolver.fs_path(root_path),
    content="Some(\"shaders/materials/root.wgsl\")",
  )
  debug_inspect(
    FileResolver::default().fs_path(root_path),
    content="Some(\"materials/root\")",
  )
}

///|
test "wesl: standard resolver exposes constants package" {
  let resolver = StandardResolver::new("shaders")
  resolver.add_constant("PI", 3.141592653589793)
  let constants_path = try! parse_module_path("constants")

  let source = resolver.resolve_source(constants_path)
  debug_inspect(source.contains("const PI = 3.141592653589793"), content="true")
  debug_inspect(resolver.fs_path(constants_path), content="None")
}

///|
test "wesl: package resolver reads codegen modules" {
  let root = CodegenModule::new("demo", "fn root() {}\n")
  root.add_submodule(CodegenModule::new("util", "fn util() {}\n"))
  let resolver = PkgResolver::new()
  resolver.add_package(CodegenPkg::new("demo_crate", root))

  debug_inspect(
    resolver.resolve_source(try! parse_module_path("demo")),
    content="\"fn root() {}\\n\"",
  )
  debug_inspect(
    resolver.resolve_source(try! parse_module_path("demo::util")),
    content="\"fn util() {}\\n\"",
  )
  debug_inspect(
    resolver.display_name(try! parse_module_path("demo::util")),
    content="Some(\"demo::util\")",
  )
}

///|
test "wesl: standard resolver delegates package imports to codegen resolver" {
  let root = CodegenModule::new("demo", "fn root() {}\n")
  root.add_submodule(CodegenModule::new("util", "fn util() {}\n"))
  let resolver = StandardResolver::new("shaders")
  resolver.add_package(CodegenPkg::new("demo_crate", root))

  debug_inspect(
    resolver.resolve_source(try! parse_module_path("demo::util")),
    content="\"fn util() {}\\n\"",
  )
  debug_inspect(
    resolver.fs_path(try! parse_module_path("demo::util")),
    content="None",
  )
}

///|
test "wesl: router dispatches to longest matching mount" {
  let router = Router::new()
  let package_path = try! parse_module_path("package")
  let bar_path = try! parse_module_path("package::bar")

  let base = VirtualResolver::new()
  base.add_module(ModulePath::new_root(), "fn root() {}\n")
  base.add_module(ModulePath::new(Absolute, ["foo"]), "fn foo() {}\n")
  base.add_module(ModulePath::new(Absolute, ["bar"]), "fn base_bar() {}\n")
  router.mount_resolver(package_path, base)

  let nested = VirtualResolver::new()
  nested.add_module(ModulePath::new_root(), "fn nested_root() {}\n")
  nested.add_module(ModulePath::new(Absolute, ["baz"]), "fn baz() {}\n")
  router.mount_resolver(bar_path, nested)

  let fallback = VirtualResolver::new()
  fallback.add_module(
    ModulePath::new(Absolute, ["external"]),
    "fn external() {}\n",
  )
  router.mount_fallback_resolver(fallback)

  debug_inspect(
    router.resolve_source(try! parse_module_path("package::foo")),
    content="\"fn foo() {}\\n\"",
  )
  debug_inspect(
    router.resolve_source(try! parse_module_path("package::bar")),
    content="\"fn nested_root() {}\\n\"",
  )
  debug_inspect(
    router.resolve_source(try! parse_module_path("package::bar::baz")),
    content="\"fn baz() {}\\n\"",
  )
  debug_inspect(
    router.resolve_source(try! parse_module_path("foo::external")),
    content="\"fn external() {}\\n\"",
  )
}

///|
test "wesl: router can mount package resolver" {
  let root = CodegenModule::new("demo", "fn root() {}\n")
  root.add_submodule(CodegenModule::new("util", "fn util() {}\n"))
  let pkg_resolver = PkgResolver::new()
  pkg_resolver.add_package(CodegenPkg::new("demo_crate", root))

  let router = Router::new()
  router.mount_pkg_resolver(try! parse_module_path("demo"), pkg_resolver)

  debug_inspect(
    router.resolve_source(try! parse_module_path("demo::util")),
    content="\"fn util() {}\\n\"",
  )
}
