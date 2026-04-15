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
