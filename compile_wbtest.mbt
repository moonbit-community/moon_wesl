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
fn compile_test_module(
  source : String,
) -> TranslationUnit raise WeslCompileError {
  parse_translation_unit(try! parse_module_path("root"), source, true)
}

///|
fn compile_test_named_items(
  names : Array[String],
) -> @hashmap.HashMap[String, Int] {
  let items : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
  for i in 0..<names.length() {
    items.set(names[i], i)
  }
  items
}

///|
fn compile_test_ast_refs(
  header : GlobalDeclarationHeader,
  names : Array[String],
) -> Array[ModuleItemRef] {
  wesl_collect_ast_item_references(
    header,
    compile_test_named_items(names),
    @hashmap.HashMap::new(),
    [],
    try! parse_module_path("root"),
  )
}

///|
test "compile: AST reference collector follows structured expression and type refs" {
  let source =
    #|struct Payload {
    #|  value: f32,
    #|}
    #|
    #|fn make_payload() -> Payload {
    #|  let item: Payload = Payload(1.0);
    #|  return item;
    #|}
  let unit = compile_test_module(source)
  let refs = compile_test_ast_refs(unit.global_declarations[1].header, [
    "Payload", "make_payload",
  ])
  inspect(refs.length(), content="1")
  inspect(refs[0] == ModuleItemRef::Local("Payload"), content="true")
}

///|
test "compile: AST reference collector follows function return type refs" {
  let source =
    #|struct Payload {
    #|  value: f32,
    #|}
    #|
    #|fn make_payload() -> Payload {
    #|  return;
    #|}
  let unit = compile_test_module(source)
  let refs = compile_test_ast_refs(unit.global_declarations[1].header, [
    "Payload", "make_payload",
  ])
  inspect(refs.length(), content="1")
  inspect(refs[0] == ModuleItemRef::Local("Payload"), content="true")
}

///|
test "compile: AST reference collector does not bind parameters inside type list" {
  let source =
    #|struct Payload {
    #|  value: f32,
    #|}
    #|
    #|fn consume(Payload: Payload) {
    #|  let next = Payload;
    #|}
  let unit = compile_test_module(source)
  let refs = compile_test_ast_refs(unit.global_declarations[1].header, [
    "Payload", "consume",
  ])
  inspect(refs.length(), content="1")
  inspect(refs[0] == ModuleItemRef::Local("Payload"), content="true")
}

///|
test "compile: AST reference collector respects local shadowing" {
  let source =
    #|struct Payload {
    #|  value: f32,
    #|}
    #|
    #|fn main() {
    #|  let Payload = 1;
    #|  let next = Payload;
    #|}
  let unit = compile_test_module(source)
  let refs = compile_test_ast_refs(unit.global_declarations[1].header, [
    "Payload", "main",
  ])
  inspect(refs.length(), content="0")
}
