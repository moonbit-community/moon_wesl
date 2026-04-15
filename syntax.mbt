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
priv struct SyntaxSpan {
  start_line : Int
  end_line : Int
}

///|
fn SyntaxSpan::context(self : SyntaxSpan, path : ModulePath) -> String {
  if self.start_line == self.end_line {
    "\{path.to_string()}:\{self.start_line}"
  } else {
    "\{path.to_string()}:\{self.start_line}-\{self.end_line}"
  }
}

///|
fn SyntaxSpan::symbol_context(
  self : SyntaxSpan,
  path : ModulePath,
  name : String,
) -> String {
  "\{name} (\{self.context(path)})"
}

///|
priv struct Attribute {
  name : String
  arguments : String?
  span : SyntaxSpan
}

///|
fn Attribute::matches(self : Attribute, target : String) -> Bool {
  self.name == target
}

///|
fn Attribute::arguments_text(self : Attribute) -> String? {
  self.arguments
}

///|
fn Attribute::syntax_span(self : Attribute) -> SyntaxSpan {
  self.span
}

///|
fn syntax_has_attribute(attributes : Array[Attribute], target : String) -> Bool {
  for attribute in attributes {
    ignore(attribute.arguments_text())
    ignore(attribute.syntax_span())
    if attribute.matches(target) {
      return true
    }
  }
  false
}

///|
priv struct ImportNode {
  path_segments : Array[String]
  rename : String?
  children : Array[ImportNode]
}

///|
fn ImportNode::is_leaf(self : ImportNode) -> Bool {
  self.children.is_empty()
}

///|
priv struct ImportedName {
  module_path : ModulePath
  item_name : String
  local_name : String
}

///|
fn syntax_concat_segments(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  let merged : Array[String] = []
  for segment in left {
    merged.push(segment)
  }
  for segment in right {
    merged.push(segment)
  }
  merged
}

///|
fn syntax_resolve_import_module_path(
  current_path : ModulePath,
  module_path_text : String,
) -> ModulePath raise WeslCompileError {
  let raw_module_path = parse_module_path(module_path_text.trim().to_string()) catch {
    err => raise WeslCompileError::Parse(err.message())
  }
  current_path.join_path(raw_module_path)
}

///|
fn syntax_flatten_import_node(
  current_path : ModulePath,
  context : String,
  prefix : Array[String],
  node : ImportNode,
  items : Array[ImportedName],
) -> Unit raise WeslCompileError {
  let full_path = syntax_concat_segments(prefix, node.path_segments)
  if node.is_leaf() {
    if full_path.length() < 2 {
      raise WeslCompileError::Parse(
        "import path must include a module and item (\{context})",
      )
    }
    let item_name = full_path[full_path.length() - 1]
    let module_path = syntax_resolve_import_module_path(
      current_path,
      full_path[:full_path.length() - 1].join("::"),
    ) catch {
      Parse(reason) => raise WeslCompileError::Parse("\{reason} (\{context})")
      err => raise err
    }
    items.push(ImportedName::{
      module_path,
      item_name,
      local_name: node.rename.unwrap_or(item_name),
    })
    return
  }
  for child in node.children {
    syntax_flatten_import_node(current_path, context, full_path, child, items)
  }
}

///|
priv struct ImportStatement {
  span : SyntaxSpan
  attributes : Array[Attribute]
  entries : Array[ImportNode]
}

///|
fn ImportStatement::is_public(self : ImportStatement) -> Bool {
  syntax_has_attribute(self.attributes, "publish")
}

///|
fn ImportStatement::flatten_items(
  self : ImportStatement,
  current_path : ModulePath,
) -> Array[ImportedName] raise WeslCompileError {
  let items : Array[ImportedName] = []
  let context = self.span.context(current_path)
  for entry in self.entries {
    syntax_flatten_import_node(current_path, context, [], entry, items)
  }
  items
}

///|
priv struct FunctionDeclaration {
  name : String
}

///|
priv struct StructDeclaration {
  name : String
}

///|
priv struct AliasDeclaration {
  name : String
  target : String?
}

///|
priv struct ConstDeclaration {
  name : String
  initializer : String?
}

///|
priv struct OverrideDeclaration {
  name : String
}

///|
priv struct LetDeclaration {
  name : String
}

///|
priv struct VarDeclaration {
  name : String?
  template_arguments : String?
}

///|
fn VarDeclaration::ident(self : VarDeclaration) -> String? {
  self.name
}

///|
fn VarDeclaration::template_args(self : VarDeclaration) -> String? {
  self.template_arguments
}

///|
priv enum GlobalDeclarationHeader {
  Function(FunctionDeclaration)
  Struct(StructDeclaration)
  Alias(AliasDeclaration)
  Const(ConstDeclaration)
  Override(OverrideDeclaration)
  Let(LetDeclaration)
  Var(VarDeclaration)
  ConstAssert
  Other
}

///|
priv struct GlobalDeclaration {
  header : GlobalDeclarationHeader
  attributes : Array[Attribute]
  source : String
  span : SyntaxSpan
}

///|
fn GlobalDeclaration::ident(self : GlobalDeclaration) -> String? {
  match self.header {
    Function(header) => Some(header.name)
    Struct(header) => Some(header.name)
    Alias(header) => Some(header.name)
    Const(header) => Some(header.name)
    Override(header) => Some(header.name)
    Let(header) => Some(header.name)
    Var(header) => {
      ignore(header.template_args())
      header.ident()
    }
    ConstAssert => None
    Other => None
  }
}

///|
fn GlobalDeclaration::is_entrypoint(self : GlobalDeclaration) -> Bool {
  match self.header {
    Function(_) =>
      syntax_has_attribute(self.attributes, "fragment") ||
      syntax_has_attribute(self.attributes, "vertex") ||
      syntax_has_attribute(self.attributes, "compute")
    _ => false
  }
}

///|
fn GlobalDeclaration::is_const_assert(self : GlobalDeclaration) -> Bool {
  self.header is GlobalDeclarationHeader::ConstAssert
}

///|
fn GlobalDeclaration::source_text(self : GlobalDeclaration) -> String {
  self.source
}

///|
priv struct TranslationUnit {
  imports : Array[ImportStatement]
  global_declarations : Array[GlobalDeclaration]
}

///|
fn TranslationUnit::declarations(
  self : TranslationUnit,
) -> Array[GlobalDeclaration] {
  self.global_declarations
}
