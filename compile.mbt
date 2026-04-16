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
pub struct CompileOptions {
  imports : Bool
  condcomp : Bool
  strip : Bool
  lower : Bool
  lazy_resolution : Bool
  mangle_root : Bool
  keep_root : Bool
  keep : Array[String]?
  features : @hashmap.HashMap[String, Bool]
}

///|
pub fn CompileOptions::default() -> CompileOptions {
  CompileOptions::{
    imports: true,
    condcomp: true,
    strip: true,
    lower: false,
    lazy_resolution: true,
    mangle_root: false,
    keep_root: false,
    keep: None,
    features: @hashmap.HashMap::new(),
  }
}

///|
pub fn CompileOptions::with_imports(
  self : CompileOptions,
  imports : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, imports, }
}

///|
pub fn CompileOptions::with_condcomp(
  self : CompileOptions,
  condcomp : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, condcomp, }
}

///|
pub fn CompileOptions::with_lower(
  self : CompileOptions,
  lower : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, lower, }
}

///|
pub fn CompileOptions::with_strip(
  self : CompileOptions,
  strip : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, strip, }
}

///|
pub fn CompileOptions::with_lazy(
  self : CompileOptions,
  enabled : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, lazy_resolution: enabled }
}

///|
pub fn CompileOptions::with_mangle_root(
  self : CompileOptions,
  mangle_root : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, mangle_root, }
}

///|
pub fn CompileOptions::with_keep_root(
  self : CompileOptions,
  keep_root : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, keep_root, }
}

///|
pub fn CompileOptions::keep_declarations(
  self : CompileOptions,
  keep : Array[String],
) -> CompileOptions {
  CompileOptions::{ ..self, keep: Some(keep) }
}

///|
pub fn CompileOptions::with_feature(
  self : CompileOptions,
  name : String,
  value : Bool,
) -> CompileOptions {
  self.features.set(name, value)
  self
}

///|
pub struct CompileResult {
  source : String
  modules : Array[ModulePath]
} derive(Debug)

///|
pub fn CompileResult::to_string(self : CompileResult) -> String {
  self.source
}

///|
priv struct ImportItem {
  export_module_path : ModulePath?
  export_name : String?
  namespace_path : ModulePath
  local_name : String
  public : Bool
  start_line : Int
  end_line : Int
}

///|
priv struct ModuleItem {
  name : String?
  kind : ModuleItemKind
  source : String
  span : SyntaxSpan
  entrypoint : Bool
  is_const_assert : Bool
  references : Array[ModuleItemRef]
}

///|
priv enum ModuleItemKind {
  Alias
  Const
  Var
  Other
}

///|
enum ModuleItemRef {
  Local(String)
  Import(String, Int)
  Qualified(String, ModulePath, String)
} derive(Eq)

///|
priv struct ParsedModule {
  path : ModulePath
  imports : Array[ImportItem]
  import_by_local : @hashmap.HashMap[String, Int]
  items : Array[ModuleItem]
  named_items : @hashmap.HashMap[String, Int]
}

///|
priv enum ExportTarget {
  Local(Int)
  ReExport(ImportItem)
  Private
  Missing
}

///|
fn wesl_is_identifier_char(code : Int) -> Bool {
  (code >= 48 && code <= 57) ||
  (code >= 65 && code <= 90) ||
  (code >= 97 && code <= 122) ||
  code == 95
}

///|
fn wesl_is_digit(code : Int) -> Bool {
  code >= 48 && code <= 57
}

///|
fn wesl_is_whitespace(code : Int) -> Bool {
  code == 32 || code == 9 || code == 10 || code == 13
}

///|
fn wesl_skip_whitespace(source : String, start : Int) -> Int {
  let mut i = start
  while i < source.length() &&
        wesl_is_whitespace(source.code_unit_at(i).to_int()) {
    i = i + 1
  }
  i
}

///|
fn wesl_skip_layout(source : String, start : Int) -> Int {
  let mut i = start
  while i < source.length() {
    i = wesl_skip_whitespace(source, i)
    if i + 1 < source.length() &&
      source.code_unit_at(i).to_int() == 47 &&
      source.code_unit_at(i + 1).to_int() == 47 {
      i += 2
      while i < source.length() && source.code_unit_at(i).to_int() != 10 {
        i += 1
      }
      continue
    }
    break
  }
  i
}

///|
fn wesl_starts_with_at(source : String, index : Int, needle : String) -> Bool {
  if index < 0 || index + needle.length() > source.length() {
    return false
  }
  source[index:index + needle.length()].to_string() == needle
}

///|
fn wesl_find_matching_delim(
  source : String,
  start : Int,
  open_code : Int,
  close_code : Int,
) -> Int raise WeslCompileError {
  let mut depth = 0
  let mut i = start
  while i < source.length() {
    let code = source.code_unit_at(i).to_int()
    if code == open_code {
      depth = depth + 1
    } else if code == close_code {
      depth = depth - 1
      if depth == 0 {
        return i
      }
    }
    i = i + 1
  }
  raise WeslCompileError::Parse("unclosed delimiter in WESL source")
}

///|
fn wesl_parse_if_primary(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let i = wesl_skip_whitespace(source, index)
  if i >= source.length() {
    raise WeslCompileError::InvalidExpression(source)
  }
  if source.code_unit_at(i).to_int() == 40 { // '('
    let (value, next_index) = wesl_parse_if_or(source, features, i + 1)
    let end_index = wesl_skip_whitespace(source, next_index)
    if end_index >= source.length() ||
      source.code_unit_at(end_index).to_int() != 41 {
      raise WeslCompileError::InvalidExpression(source)
    }
    return (value, end_index + 1)
  }
  let mut end_index = i
  while end_index < source.length() &&
        wesl_is_identifier_char(source.code_unit_at(end_index).to_int()) {
    end_index = end_index + 1
  }
  if end_index == i {
    raise WeslCompileError::InvalidExpression(source)
  }
  let ident = source[i:end_index].to_string()
  let value = if ident == "true" {
    true
  } else if ident == "false" {
    false
  } else {
    features.get(ident).unwrap_or(false)
  }
  (value, end_index)
}

///|
fn wesl_parse_if_not(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let i = wesl_skip_whitespace(source, index)
  if i < source.length() && source.code_unit_at(i).to_int() == 33 { // '!'
    let (value, next_index) = wesl_parse_if_not(source, features, i + 1)
    (!value, next_index)
  } else {
    wesl_parse_if_primary(source, features, i)
  }
}

///|
fn wesl_parse_if_and(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let (initial, initial_index) = wesl_parse_if_not(source, features, index)
  let mut lhs = initial
  let mut next_index = initial_index
  let mut i = wesl_skip_whitespace(source, next_index)
  while i + 1 < source.length() && wesl_starts_with_at(source, i, "&&") {
    let (rhs, rhs_index) = wesl_parse_if_not(source, features, i + 2)
    lhs = lhs && rhs
    next_index = rhs_index
    i = wesl_skip_whitespace(source, next_index)
  }
  (lhs, next_index)
}

///|
fn wesl_parse_if_or(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let (initial, initial_index) = wesl_parse_if_and(source, features, index)
  let mut lhs = initial
  let mut next_index = initial_index
  let mut i = wesl_skip_whitespace(source, next_index)
  while i + 1 < source.length() && wesl_starts_with_at(source, i, "||") {
    let (rhs, rhs_index) = wesl_parse_if_and(source, features, i + 2)
    lhs = lhs || rhs
    next_index = rhs_index
    i = wesl_skip_whitespace(source, next_index)
  }
  (lhs, next_index)
}

///|
fn wesl_parse_if_value(
  expr : String,
  features : @hashmap.HashMap[String, Bool],
) -> Bool raise WeslCompileError {
  let source = expr.trim().to_string()
  if source == "" {
    raise WeslCompileError::InvalidExpression(expr)
  }
  let (value, next_index) = wesl_parse_if_or(source, features, 0)
  let end_index = wesl_skip_whitespace(source, next_index)
  if end_index != source.length() {
    raise WeslCompileError::InvalidExpression(expr)
  }
  value
}

///|
fn wesl_find_condcomp_block(
  source : String,
  start : Int,
) -> (Int, Int) raise WeslCompileError {
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut index = start
  while index < source.length() {
    if index + 1 < source.length() &&
      source.code_unit_at(index).to_int() == 47 &&
      source.code_unit_at(index + 1).to_int() == 47 {
      index += 2
      while index < source.length() && source.code_unit_at(index).to_int() != 10 {
        index += 1
      }
      continue
    }
    let code = source.code_unit_at(index).to_int()
    if code == 40 {
      paren_depth += 1
    } else if code == 41 {
      paren_depth -= 1
    } else if code == 91 {
      bracket_depth += 1
    } else if code == 93 {
      bracket_depth -= 1
    } else if code == 123 && paren_depth == 0 && bracket_depth == 0 {
      let block_end = wesl_find_matching_delim(source, index, 123, 125)
      return (index, block_end + 1)
    }
    index += 1
  }
  raise WeslCompileError::Parse("missing block after conditional attribute")
}

///|
fn wesl_find_condcomp_region(
  source : String,
  start : Int,
) -> (Int, Int) raise WeslCompileError {
  let region_start = wesl_skip_layout(source, start)
  if region_start >= source.length() {
    raise WeslCompileError::Parse(
      "missing declaration after conditional attribute",
    )
  }
  let first_code = source.code_unit_at(region_start).to_int()
  if first_code == 123 {
    let block_end = wesl_find_matching_delim(source, region_start, 123, 125)
    return (region_start, block_end + 1)
  }
  let tokens = parser_lex(source[region_start:source.length()].to_string())
  let block_like = match tokens.get(0) {
    Some(Ident(keyword, _, _, _)) =>
      keyword == "fn" ||
      keyword == "struct" ||
      keyword == "if" ||
      keyword == "switch" ||
      keyword == "loop" ||
      keyword == "for" ||
      keyword == "while" ||
      keyword == "continuing"
    _ => false
  }
  if block_like {
    let (_, region_end) = wesl_find_condcomp_block(source, region_start)
    return (region_start, region_end)
  }
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  let mut index = region_start
  while index < source.length() {
    if index + 1 < source.length() &&
      source.code_unit_at(index).to_int() == 47 &&
      source.code_unit_at(index + 1).to_int() == 47 {
      index += 2
      while index < source.length() && source.code_unit_at(index).to_int() != 10 {
        index += 1
      }
      continue
    }
    let code = source.code_unit_at(index).to_int()
    if code == 40 {
      paren_depth += 1
    } else if code == 41 {
      if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0 {
        return (region_start, index)
      }
      paren_depth -= 1
    } else if code == 91 {
      bracket_depth += 1
    } else if code == 93 {
      bracket_depth -= 1
    } else if code == 123 {
      brace_depth += 1
    } else if code == 125 {
      if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0 {
        return (region_start, index)
      }
      brace_depth -= 1
    } else if code == 44 &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      return (region_start, index + 1)
    } else if code == 59 &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      return (region_start, index + 1)
    }
    index += 1
  }
  (region_start, source.length())
}

///|
fn wesl_apply_condcomp(
  source : String,
  features : @hashmap.HashMap[String, Bool],
) -> String raise WeslCompileError {
  let mut out = ""
  let mut index = 0
  while index < source.length() {
    if wesl_starts_with_at(source, index, "@if") {
      let expr_start = wesl_skip_layout(source, index + 3)
      if expr_start >= source.length() ||
        source.code_unit_at(expr_start).to_int() != 40 {
        raise WeslCompileError::InvalidExpression(
          source[index:source.length()].to_string(),
        )
      }
      let expr_end = wesl_find_matching_delim(source, expr_start, 40, 41)
      let expr = source[expr_start + 1:expr_end].to_string()
      let (region_start, region_end) = wesl_find_condcomp_region(
        source,
        expr_end + 1,
      )
      let mut selected : String? = None
      if wesl_parse_if_value(expr, features) {
        selected = Some(
          wesl_apply_condcomp(
            source[region_start:region_end].to_string(),
            features,
          ),
        )
      }
      let mut next_index = region_end
      while true {
        let else_start = wesl_skip_layout(source, next_index)
        if !wesl_starts_with_at(source, else_start, "@else") {
          break
        }
        let tail_start = wesl_skip_layout(source, else_start + 5)
        if wesl_starts_with_at(source, tail_start, "if") {
          let elif_expr_start = wesl_skip_layout(source, tail_start + 2)
          if elif_expr_start >= source.length() ||
            source.code_unit_at(elif_expr_start).to_int() != 40 {
            raise WeslCompileError::InvalidExpression(
              source[else_start:source.length()].to_string(),
            )
          }
          let elif_expr_end = wesl_find_matching_delim(
            source, elif_expr_start, 40, 41,
          )
          let elif_expr = source[elif_expr_start + 1:elif_expr_end].to_string()
          let (elif_region_start, elif_region_end) = wesl_find_condcomp_region(
            source,
            elif_expr_end + 1,
          )
          if selected is None && wesl_parse_if_value(elif_expr, features) {
            selected = Some(
              wesl_apply_condcomp(
                source[elif_region_start:elif_region_end].to_string(),
                features,
              ),
            )
          }
          next_index = elif_region_end
          continue
        }
        let (else_region_start, else_region_end) = wesl_find_condcomp_region(
          source, tail_start,
        )
        if selected is None {
          selected = Some(
            wesl_apply_condcomp(
              source[else_region_start:else_region_end].to_string(),
              features,
            ),
          )
        }
        next_index = else_region_end
        break
      }
      out = out + selected.unwrap_or("")
      index = next_index
      continue
    }
    out = out + source[index:index + 1].to_string()
    index = index + 1
  }
  out
}

///|
fn wesl_push_unique(items : Array[String], value : String) -> Unit {
  if value == "" {
    return
  }
  for item in items {
    if item == value {
      return
    }
  }
  items.push(value)
}

///|
fn wesl_scopes_contain(
  scopes : Array[Array[String]],
  scope_depth : Int,
  name : String,
) -> Bool {
  let mut depth = scope_depth
  while depth >= 0 {
    for item in scopes[depth] {
      if item == name {
        return true
      }
    }
    depth -= 1
  }
  false
}

///|
fn wesl_bind_scope(
  scopes : Array[Array[String]],
  scope_depth : Int,
  name : String,
) -> Unit {
  wesl_push_unique(scopes[scope_depth], name)
}

///|
fn wesl_push_unique_item_ref(
  items : Array[ModuleItemRef],
  value : ModuleItemRef,
) -> Unit {
  for item in items {
    if item == value {
      return
    }
  }
  items.push(value)
}

///|
fn wesl_resolve_module_path(
  current_path : ModulePath,
  module_path_text : String,
) -> ModulePath raise WeslCompileError {
  let raw_module_path = parse_module_path(module_path_text.trim().to_string()) catch {
    err => raise WeslCompileError::Parse(err.message())
  }
  match raw_module_path.origin {
    Package(name) if raw_module_path.components.is_empty() =>
      return ModulePath::new(Absolute, [name])
    _ => ()
  }
  current_path.join_path(raw_module_path)
}

///|
fn wesl_slice_segments(
  segments : Array[String],
  start : Int,
  end_ : Int,
) -> Array[String] {
  let out : Array[String] = []
  for i = start; i < end_; i = i + 1 {
    out.push(segments[i])
  }
  out
}

///|
fn wesl_extend_module_path(
  base_path : ModulePath,
  extra_segments : Array[String],
) -> ModulePath raise WeslCompileError {
  if extra_segments.is_empty() {
    return base_path
  }
  let suffix = extra_segments.join("::")
  let full_path = "\{base_path.to_string()}::\{suffix}"
  parse_module_path(full_path) catch {
    err => raise WeslCompileError::Parse(err.message())
  }
}

///|
fn wesl_token_text(source : String, token : ParserToken) -> String {
  source[token.start():token.end()].to_string()
}

///|
fn wesl_is_declaration_keyword(name : String) -> Bool {
  name == "fn" ||
  name == "struct" ||
  name == "alias" ||
  name == "const" ||
  name == "override" ||
  name == "let" ||
  name == "var"
}

///|
fn wesl_binding_keyword_before(
  tokens : Array[ParserToken],
  index : Int,
) -> String? {
  if index <= 0 {
    return None
  }
  match tokens[index - 1] {
    Ident(previous, _, _, _) if wesl_is_declaration_keyword(previous) =>
      return Some(previous)
    Gt(_, _, _) => {
      let mut depth = 1
      let mut i = index - 2
      while i >= 0 {
        match tokens[i] {
          Gt(_, _, _) => depth += 1
          Lt(_, _, _) => {
            depth -= 1
            if depth == 0 {
              break
            }
          }
          _ => ()
        }
        i -= 1
      }
      if i > 0 {
        match tokens[i - 1] {
          Ident(previous, _, _, _) if wesl_is_declaration_keyword(previous) =>
            return Some(previous)
          _ => ()
        }
      }
    }
    _ => ()
  }
  None
}

///|
fn wesl_is_bound_identifier(
  source : String,
  tokens : Array[ParserToken],
  index : Int,
) -> Bool {
  if wesl_binding_keyword_before(tokens, index) is Some(_) {
    return true
  }
  if index + 1 < tokens.length() {
    match tokens[index + 1] {
      Other(_, _, _) => wesl_token_text(source, tokens[index + 1]) == ":"
      _ => false
    }
  } else {
    false
  }
}

///|
fn wesl_collect_qualified_segments(
  source : String,
  tokens : Array[ParserToken],
  start_index : Int,
) -> (Array[String], String, Int) {
  let segments : Array[String] = []
  let start_offset = tokens[start_index].start()
  let mut end_offset = tokens[start_index].end()
  let mut index = start_index
  while index < tokens.length() {
    match tokens[index] {
      Ident(segment, _, end_, _) => {
        segments.push(segment)
        end_offset = end_
        index += 1
      }
      _ => break
    }
    if index + 1 < tokens.length() &&
      tokens[index] is DoubleColon(_, _, _) &&
      tokens[index + 1] is Ident(_, _, _, _) {
      index += 1
      continue
    }
    break
  }
  (segments, source[start_offset:end_offset].to_string(), index)
}

///|
fn wesl_resolve_qualified_import_target(
  import_item : ImportItem,
  segments : Array[String],
) -> (ModulePath, String) raise WeslCompileError {
  let item_name = segments[segments.length() - 1]
  let module_path = wesl_extend_module_path(
    import_item.namespace_path,
    wesl_slice_segments(segments, 1, segments.length() - 1),
  )
  (module_path, item_name)
}

///|
fn wesl_resolve_direct_qualified_target(
  current_path : ModulePath,
  segments : Array[String],
) -> (ModulePath, String) raise WeslCompileError {
  let item_name = segments[segments.length() - 1]
  let module_path = wesl_resolve_module_path(
    current_path,
    wesl_slice_segments(segments, 0, segments.length() - 1).join("::"),
  )
  (module_path, item_name)
}

///|
fn wesl_import_named_target(import_item : ImportItem) -> (ModulePath, String)? {
  match import_item.export_module_path {
    Some(export_module_path) =>
      match import_item.export_name {
        Some(export_name) => Some((export_module_path, export_name))
        None => None
      }
    None => None
  }
}

///|
fn wesl_collect_item_references(
  source : String,
  item_name : String?,
  named_items : @hashmap.HashMap[String, Int],
  import_by_local : @hashmap.HashMap[String, Int],
  imports : Array[ImportItem],
  current_path : ModulePath,
) -> Array[ModuleItemRef] {
  let references : Array[ModuleItemRef] = []
  let tokens = parser_lex(source)
  let scopes : Array[Array[String]] = [[]]
  let mut scope_depth = 0
  let mut consumed_item_decl = item_name is None
  let mut index = 0
  while index < tokens.length() {
    match tokens[index] {
      LBrace(_, _, _) => {
        scope_depth += 1
        if scope_depth < scopes.length() {
          scopes[scope_depth] = []
        } else {
          scopes.push([])
        }
      }
      RBrace(_, _, _) => if scope_depth > 0 { scope_depth -= 1 }
      Ident(name, _, _, _) => {
        let is_binding = wesl_is_bound_identifier(source, tokens, index)
        if is_binding {
          let is_item_decl = match item_name {
            Some(current_item_name) =>
              !consumed_item_decl && name == current_item_name
            None => false
          }
          if is_item_decl {
            consumed_item_decl = true
          } else {
            wesl_bind_scope(scopes, scope_depth, name)
          }
          index += 1
          continue
        }
        if index + 1 < tokens.length() &&
          tokens[index + 1] is DoubleColon(_, _, _) {
          let (segments, raw_text, next_index) = wesl_collect_qualified_segments(
            source, tokens, index,
          )
          if segments.length() >= 2 &&
            !wesl_scopes_contain(scopes, scope_depth, segments[0]) {
            match import_by_local.get(segments[0]) {
              Some(import_index) => {
                let (target_path, target_name) = wesl_resolve_qualified_import_target(
                  imports[import_index],
                  segments,
                ) catch {
                  _ =>
                    (
                      imports[import_index].namespace_path,
                      segments[segments.length() - 1],
                    )
                }
                wesl_push_unique_item_ref(
                  references,
                  ModuleItemRef::Qualified(raw_text, target_path, target_name),
                )
              }
              None =>
                if segments[0] == "package" ||
                  segments[0] == "self" ||
                  segments[0] == "super" {
                  let (target_path, target_name) = wesl_resolve_direct_qualified_target(
                    current_path, segments,
                  ) catch {
                    _ => (current_path, segments[segments.length() - 1])
                  }
                  wesl_push_unique_item_ref(
                    references,
                    ModuleItemRef::Qualified(raw_text, target_path, target_name),
                  )
                }
            }
          }
          index = next_index
          continue
        }
        if wesl_scopes_contain(scopes, scope_depth, name) {
          index += 1
          continue
        }
        if named_items.contains(name) {
          wesl_push_unique_item_ref(references, ModuleItemRef::Local(name))
        } else {
          match import_by_local.get(name) {
            Some(import_index) =>
              if wesl_import_named_target(imports[import_index]) is Some(_) {
                wesl_push_unique_item_ref(
                  references,
                  ModuleItemRef::Import(name, import_index),
                )
              }
            None => ()
          }
        }
      }
      _ => ()
    }
    index += 1
  }
  references
}

///|
fn wesl_replace_identifier(
  source : String,
  old_name : String,
  new_name : String,
) -> String {
  if old_name == new_name || old_name == "" {
    return source
  }
  let mut out = ""
  let mut index = 0
  while index < source.length() {
    let can_match = index + old_name.length() <= source.length() &&
      source[index:index + old_name.length()].to_string() == old_name
    if can_match {
      let prev_code = if index == 0 {
        -1
      } else {
        source.code_unit_at(index - 1).to_int()
      }
      let next_code = if index + old_name.length() >= source.length() {
        -1
      } else {
        source.code_unit_at(index + old_name.length()).to_int()
      }
      let prev_ok = prev_code < 0 || !wesl_is_identifier_char(prev_code)
      let next_ok = next_code < 0 || !wesl_is_identifier_char(next_code)
      if prev_ok && next_ok {
        out = out + new_name
        index = index + old_name.length()
        continue
      }
    }
    out = out + source[index:index + 1].to_string()
    index = index + 1
  }
  out
}

///|
fn wesl_replace_reference_identifier(
  source : String,
  old_name : String,
  new_name : String,
  item_name : String?,
) -> String {
  if old_name == new_name || old_name == "" {
    return source
  }
  let tokens = parser_lex(source)
  let scopes : Array[Array[String]] = [[]]
  let mut scope_depth = 0
  let mut consumed_item_decl = item_name is None
  let mut out = ""
  let mut previous_end = 0
  for i in 0..<tokens.length() {
    let token = tokens[i]
    let start = token.start()
    let end_ = token.end()
    if previous_end < start {
      out = out + source[previous_end:start].to_string()
    }
    match token {
      LBrace(_, _, _) => {
        scope_depth += 1
        if scope_depth < scopes.length() {
          scopes[scope_depth] = []
        } else {
          scopes.push([])
        }
        out = out + source[start:end_].to_string()
      }
      RBrace(_, _, _) => {
        if scope_depth > 0 {
          scope_depth -= 1
        }
        out = out + source[start:end_].to_string()
      }
      Ident(name, _, _, _) => {
        let original = source[start:end_].to_string()
        if wesl_is_bound_identifier(source, tokens, i) {
          let is_item_decl = match item_name {
            Some(current_item_name) =>
              !consumed_item_decl && name == current_item_name
            None => false
          }
          if is_item_decl {
            consumed_item_decl = true
          } else {
            wesl_bind_scope(scopes, scope_depth, name)
          }
          out = out + original
        } else if name == old_name &&
          !wesl_scopes_contain(scopes, scope_depth, name) {
          out = out + new_name
        } else {
          out = out + original
        }
      }
      _ => out = out + source[start:end_].to_string()
    }
    previous_end = end_
  }
  if previous_end < source.length() {
    out = out + source[previous_end:source.length()].to_string()
  }
  out
}

///|
fn wesl_replace_global_identifier(
  source : String,
  old_name : String,
  new_name : String,
  item_name : String?,
) -> String {
  if old_name == new_name || old_name == "" {
    return source
  }
  let tokens = parser_lex(source)
  let scopes : Array[Array[String]] = [[]]
  let mut scope_depth = 0
  let mut consumed_item_decl = item_name is None
  let mut out = ""
  let mut previous_end = 0
  for i in 0..<tokens.length() {
    let token = tokens[i]
    let start = token.start()
    let end_ = token.end()
    if previous_end < start {
      out = out + source[previous_end:start].to_string()
    }
    match token {
      LBrace(_, _, _) => {
        scope_depth += 1
        if scope_depth < scopes.length() {
          scopes[scope_depth] = []
        } else {
          scopes.push([])
        }
        out = out + source[start:end_].to_string()
      }
      RBrace(_, _, _) => {
        if scope_depth > 0 {
          scope_depth -= 1
        }
        out = out + source[start:end_].to_string()
      }
      Ident(name, _, _, _) => {
        let original = source[start:end_].to_string()
        if wesl_is_bound_identifier(source, tokens, i) {
          let is_item_decl = match item_name {
            Some(current_item_name) =>
              !consumed_item_decl && name == current_item_name
            None => false
          }
          if is_item_decl {
            consumed_item_decl = true
            if name == old_name {
              out = out + new_name
            } else {
              out = out + original
            }
          } else {
            wesl_bind_scope(scopes, scope_depth, name)
            out = out + original
          }
        } else if name == old_name &&
          !wesl_scopes_contain(scopes, scope_depth, name) {
          out = out + new_name
        } else {
          out = out + original
        }
      }
      _ => out = out + source[start:end_].to_string()
    }
    previous_end = end_
  }
  if previous_end < source.length() {
    out = out + source[previous_end:source.length()].to_string()
  }
  out
}

///|
fn wesl_decl_key(path : ModulePath, name : String) -> String {
  "\{path.to_string()}::\{name}"
}

///|
fn wesl_is_used_decl(
  used_decls : @hashmap.HashMap[String, Bool],
  path : ModulePath,
  name : String,
) -> Bool {
  used_decls.contains(wesl_decl_key(path, name))
}

///|
fn wesl_item_kind(header : GlobalDeclarationHeader) -> ModuleItemKind {
  match header {
    Alias(_) => ModuleItemKind::Alias
    Const(_) => ModuleItemKind::Const
    Var(_) => ModuleItemKind::Var
    _ => ModuleItemKind::Other
  }
}

///|
fn wesl_item_has_cycle_semantics(item : ModuleItem) -> Bool {
  match item.kind {
    Alias => true
    Const => true
    Var => true
    Other => false
  }
}

///|
fn wesl_module_export_target(
  parsed_module : ParsedModule,
  name : String,
) -> ExportTarget {
  match parsed_module.named_items.get(name) {
    Some(index) => ExportTarget::Local(index)
    None =>
      match parsed_module.import_by_local.get(name) {
        Some(index) =>
          if parsed_module.imports[index].public &&
            wesl_import_named_target(parsed_module.imports[index]) is Some(_) {
            ExportTarget::ReExport(parsed_module.imports[index])
          } else {
            ExportTarget::Private
          }
        None => ExportTarget::Missing
      }
  }
}

///|
fn wesl_resolve_export_target(
  path : ModulePath,
  name : String,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
) -> (ModulePath, String) raise WeslCompileError {
  guard modules.get(path) is Some(parsed_module) else {
    raise WeslCompileError::MissingDecl(path, name)
  }
  match wesl_module_export_target(parsed_module, name) {
    ExportTarget::Local(_) => (path, name)
    ExportTarget::ReExport(import_item) =>
      match wesl_import_named_target(import_item) {
        Some((import_path, import_name)) =>
          wesl_resolve_export_target(import_path, import_name, modules)
        None => raise WeslCompileError::MissingDecl(path, name)
      }
    ExportTarget::Private => raise WeslCompileError::Private(name, path)
    ExportTarget::Missing => raise WeslCompileError::MissingDecl(path, name)
  }
}

///|
fn[R : Resolver] wesl_preload_import_item(
  import_item : ImportItem,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
) -> Unit raise WeslCompileError {
  let mut missing_named_target : (ModulePath, String)? = None
  match wesl_import_named_target(import_item) {
    Some((import_path, import_name)) =>
      try
        wesl_load_module(import_path, resolver, options, modules, order)
      catch {
        _ => ()
      } noraise {
        loaded =>
          match wesl_module_export_target(loaded, import_name) {
            ExportTarget::Local(_) => return
            ExportTarget::ReExport(_) => return
            ExportTarget::Private =>
              raise WeslCompileError::Private(import_name, loaded.path)
            ExportTarget::Missing =>
              missing_named_target = Some((loaded.path, import_name))
          }
      }
    None => ()
  }
  ignore(
    wesl_load_module(
      import_item.namespace_path,
      resolver,
      options,
      modules,
      order,
    ),
  ) catch {
    err =>
      match missing_named_target {
        Some((missing_path, missing_name)) =>
          raise WeslCompileError::MissingDecl(missing_path, missing_name)
        None => raise err
      }
  }
}

///|
fn[R : Resolver] wesl_load_module(
  path : ModulePath,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
) -> ParsedModule raise WeslCompileError {
  match modules.get(path) {
    Some(existing) => existing
    None => {
      let raw_source = R::resolve_source(resolver, path) catch {
        err => raise WeslCompileError::Resolve(err)
      }
      let source = if options.condcomp {
        wesl_apply_condcomp(raw_source, options.features)
      } else {
        raw_source
      }
      let translation_unit = parse_translation_unit(
        path,
        source,
        options.imports,
      )
      let imports : Array[ImportItem] = []
      let parsed_items : Array[ModuleItem] = []
      let named_items : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
      for statement in translation_unit.imports {
        for imported_name in statement.flatten_items(path) {
          imports.push(ImportItem::{
            export_module_path: imported_name.export_module_path,
            export_name: imported_name.export_name,
            namespace_path: imported_name.namespace_path,
            local_name: imported_name.local_name,
            public: statement.is_public(),
            start_line: statement.span.start_line,
            end_line: statement.span.end_line,
          })
        }
      }
      for decl in translation_unit.global_declarations {
        match decl.ident() {
          Some(name) =>
            if named_items.contains(name) {
              raise WeslCompileError::DuplicateSymbol(
                decl.span.symbol_context(path, name),
              )
            } else {
              named_items.set(name, parsed_items.length())
            }
          None => ()
        }
        parsed_items.push(ModuleItem::{
          name: decl.ident(),
          kind: wesl_item_kind(decl.header),
          source: decl.source,
          span: decl.span,
          entrypoint: decl.is_entrypoint(),
          is_const_assert: decl.is_const_assert(),
          references: [],
        })
      }
      let import_by_local : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
      for i in 0..<imports.length() {
        let import_item = imports[i]
        if named_items.contains(import_item.local_name) ||
          import_by_local.contains(import_item.local_name) {
          raise WeslCompileError::DuplicateSymbol(
            SyntaxSpan::{
              start_line: import_item.start_line,
              end_line: import_item.end_line,
            }.symbol_context(path, import_item.local_name),
          )
        }
        import_by_local.set(import_item.local_name, i)
      }
      for i in 0..<parsed_items.length() {
        let parsed = parsed_items[i]
        let references = wesl_collect_item_references(
          parsed.source,
          parsed.name,
          named_items,
          import_by_local,
          imports,
          path,
        )
        parsed_items[i] = ModuleItem::{ ..parsed, references, }
      }
      let parsed_module = ParsedModule::{
        path,
        imports,
        import_by_local,
        items: parsed_items,
        named_items,
      }
      modules.set(path, parsed_module)
      order.push(path)
      if options.imports && (!options.strip || !options.lazy_resolution) {
        for import_item in parsed_module.imports {
          ignore(
            wesl_preload_import_item(
              import_item, resolver, options, modules, order,
            ),
          )
        }
      }
      parsed_module
    }
  }
}

///|
fn[R : Resolver] wesl_mark_module_used(
  path : ModulePath,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
  used_modules : @hashmap.HashMap[ModulePath, Bool],
  used_decls : @hashmap.HashMap[String, Bool],
) -> ParsedModule raise WeslCompileError {
  let parsed_module = wesl_load_module(path, resolver, options, modules, order)
  if used_modules.contains(path) {
    return parsed_module
  }
  used_modules.set(path, true)
  for item in parsed_module.items {
    if !item.is_const_assert {
      continue
    }
    ignore(
      wesl_mark_item_refs(
        path, parsed_module, item, resolver, options, modules, order, used_modules,
        used_decls,
      ),
    )
  }
  parsed_module
}

///|
fn[R : Resolver] wesl_mark_named_decl(
  path : ModulePath,
  name : String,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
  used_modules : @hashmap.HashMap[ModulePath, Bool],
  used_decls : @hashmap.HashMap[String, Bool],
) -> Unit raise WeslCompileError {
  let parsed_module = wesl_mark_module_used(
    path, resolver, options, modules, order, used_modules, used_decls,
  )
  let key = wesl_decl_key(path, name)
  if used_decls.contains(key) {
    return
  }
  match wesl_module_export_target(parsed_module, name) {
    ExportTarget::Local(index) => {
      used_decls.set(key, true)
      let item = parsed_module.items[index]
      ignore(
        wesl_mark_item_refs(
          path, parsed_module, item, resolver, options, modules, order, used_modules,
          used_decls,
        ),
      )
    }
    ExportTarget::ReExport(import_item) => {
      used_decls.set(key, true)
      match wesl_import_named_target(import_item) {
        Some((import_path, import_name)) =>
          ignore(
            wesl_mark_named_decl(
              import_path, import_name, resolver, options, modules, order, used_modules,
              used_decls,
            ),
          )
        None => ()
      }
    }
    ExportTarget::Private => raise WeslCompileError::Private(name, path)
    ExportTarget::Missing => raise WeslCompileError::MissingDecl(path, name)
  }
}

///|
fn wesl_root_keep_names(
  root : ParsedModule,
  options : CompileOptions,
) -> Array[String] {
  let keep_names : Array[String] = []
  if !options.strip || options.keep_root {
    for entry in root.named_items.iter() {
      let (name, _) = entry
      keep_names.push(name)
    }
    return keep_names
  }
  match options.keep {
    Some(keep) => {
      for name in keep {
        if root.named_items.contains(name) {
          keep_names.push(name)
        }
      }
      keep_names
    }
    None => {
      for item in root.items {
        if item.entrypoint && item.name is Some(name) {
          keep_names.push(name)
        }
      }
      keep_names
    }
  }
}

///|
fn[R : Resolver] wesl_mark_item_refs(
  path : ModulePath,
  parsed_module : ParsedModule,
  item : ModuleItem,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
  used_modules : @hashmap.HashMap[ModulePath, Bool],
  used_decls : @hashmap.HashMap[String, Bool],
) -> Unit raise WeslCompileError {
  for reference in item.references {
    match reference {
      ModuleItemRef::Local(name) =>
        ignore(
          wesl_mark_named_decl(
            path, name, resolver, options, modules, order, used_modules, used_decls,
          ),
        )
      ModuleItemRef::Import(_, import_index) => {
        let import_item = parsed_module.imports[import_index]
        match wesl_import_named_target(import_item) {
          Some((import_path, import_name)) =>
            ignore(
              wesl_mark_named_decl(
                import_path, import_name, resolver, options, modules, order, used_modules,
                used_decls,
              ),
            )
          None => ()
        }
      }
      ModuleItemRef::Qualified(_, target_path, target_name) =>
        ignore(
          wesl_mark_named_decl(
            target_path, target_name, resolver, options, modules, order, used_modules,
            used_decls,
          ),
        )
    }
  }
}

///|
fn wesl_apply_replacements(
  source : String,
  replacements : Array[(String, String)],
) -> String {
  let mut out = source
  for replacement in replacements {
    out = wesl_replace_identifier(out, replacement.0, replacement.1)
  }
  out
}

///|
fn wesl_lower_source(source : String) -> String raise WeslCompileError {
  let alias_replacements : Array[(String, String)] = []
  let const_replacements : Array[(String, String)] = []
  let kept_items : Array[ModuleItem] = []
  for decl in parse_global_declarations(source) {
    let parsed = ModuleItem::{
      name: decl.ident(),
      kind: wesl_item_kind(decl.header),
      source: decl.source,
      span: decl.span,
      entrypoint: decl.is_entrypoint(),
      is_const_assert: decl.is_const_assert(),
      references: [],
    }
    match decl.header {
      Alias(alias_decl) =>
        match alias_decl.target {
          Some(target) => {
            alias_replacements.push(
              (
                alias_decl.name,
                wesl_apply_replacements(
                  wesl_apply_replacements(target, alias_replacements),
                  const_replacements,
                ),
              ),
            )
            continue
          }
          None => kept_items.push(parsed)
        }
      Const(const_decl) =>
        match const_decl.initializer {
          Some(initializer) => {
            const_replacements.push(
              (
                const_decl.name,
                "(\{wesl_apply_replacements(wesl_apply_replacements(initializer, alias_replacements), const_replacements)})",
              ),
            )
            continue
          }
          None => kept_items.push(parsed)
        }
      _ => kept_items.push(parsed)
    }
  }
  let lowered : Array[String] = []
  for item in kept_items {
    let lowered_item = wesl_apply_replacements(
        wesl_apply_replacements(item.source, alias_replacements),
        const_replacements,
      )
      .trim()
      .to_string()
    if lowered_item != "" {
      lowered.push(lowered_item)
    }
  }
  lowered.join("\n\n")
}

///|
fn wesl_cycle_reference_target(
  current_path : ModulePath,
  parsed_module : ParsedModule,
  reference : ModuleItemRef,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
) -> (ModulePath, String)? {
  match reference {
    Local(name) => Some((current_path, name))
    Import(_, import_index) =>
      match wesl_import_named_target(parsed_module.imports[import_index]) {
        Some((import_path, import_name)) => {
          let target = wesl_resolve_export_target(
            import_path, import_name, modules,
          ) catch {
            _ => return None
          }
          Some(target)
        }
        None => None
      }
    Qualified(_, target_path, target_name) => {
      let target = wesl_resolve_export_target(target_path, target_name, modules) catch {
        _ => return None
      }
      Some(target)
    }
  }
}

///|
fn wesl_validate_decl_cycle(
  path : ModulePath,
  name : String,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  states : @hashmap.HashMap[String, Int],
) -> Unit raise WeslCompileError {
  let key = wesl_decl_key(path, name)
  match states.get(key) {
    Some(state) =>
      if state == 1 {
        guard modules.get(path) is Some(parsed_module) else { return }
        guard parsed_module.named_items.get(name) is Some(index) else { return }
        let item = parsed_module.items[index]
        raise WeslCompileError::CircularDecl(
          item.span.symbol_context(path, name),
        )
      } else {
        return
      }
    None => ()
  }
  guard modules.get(path) is Some(parsed_module) else { return }
  guard parsed_module.named_items.get(name) is Some(index) else { return }
  let item = parsed_module.items[index]
  if !wesl_item_has_cycle_semantics(item) {
    states.set(key, 2)
    return
  }
  states.set(key, 1)
  for reference in item.references {
    match wesl_cycle_reference_target(path, parsed_module, reference, modules) {
      Some((target_path, target_name)) =>
        ignore(
          wesl_validate_decl_cycle(target_path, target_name, modules, states),
        )
      None => ()
    }
  }
  states.set(key, 2)
}

///|
fn wesl_validate_loaded_cycles(
  order : Array[ModulePath],
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
) -> Unit raise WeslCompileError {
  let states : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
  for path in order {
    guard modules.get(path) is Some(parsed_module) else { continue }
    for item in parsed_module.items {
      guard item.name is Some(name) else { continue }
      if !wesl_item_has_cycle_semantics(item) {
        continue
      }
      ignore(wesl_validate_decl_cycle(path, name, modules, states))
    }
  }
}

///|
fn wesl_item_context(path : ModulePath, item : ModuleItem) -> String {
  match item.name {
    Some(name) => item.span.symbol_context(path, name)
    None => item.span.context(path)
  }
}

///|
fn wesl_is_matrix_type_name(name : String) -> Bool {
  if name.length() < 6 || name[:3].to_string() != "mat" {
    return false
  }
  let mut index = 3
  let mut saw_rows = false
  while index < name.length() &&
        wesl_is_digit(name.code_unit_at(index).to_int()) {
    saw_rows = true
    index += 1
  }
  if !saw_rows ||
    index >= name.length() ||
    name.code_unit_at(index).to_int() != 120 {
    return false
  }
  index += 1
  let mut saw_cols = false
  while index < name.length() &&
        wesl_is_digit(name.code_unit_at(index).to_int()) {
    saw_cols = true
    index += 1
  }
  if !saw_cols {
    return false
  }
  if index == name.length() {
    return true
  }
  if index + 1 == name.length() {
    let suffix = name.code_unit_at(index).to_int()
    return suffix == 102 || suffix == 104
  }
  false
}

///|
fn wesl_is_float_scalar_name(name : String) -> Bool {
  name == "f16" || name == "f32"
}

///|
fn wesl_skip_angle_tokens(
  tokens : Array[ParserToken],
  start_index : Int,
) -> Int {
  let mut depth = 0
  let mut index = start_index
  while index < tokens.length() {
    match tokens[index] {
      Lt(_, _, _) => depth += 1
      Gt(_, _, _) => {
        depth -= 1
        if depth == 0 {
          return index + 1
        }
      }
      _ => ()
    }
    index += 1
  }
  tokens.length()
}

///|
fn wesl_find_binding_name_index(
  tokens : Array[ParserToken],
  keyword_index : Int,
) -> Int? {
  let mut index = keyword_index + 1
  if index < tokens.length() && tokens[index] is Lt(_, _, _) {
    index = wesl_skip_angle_tokens(tokens, index)
  }
  if index < tokens.length() {
    match tokens[index] {
      Ident(_, _, _, _) => Some(index)
      _ => None
    }
  } else {
    None
  }
}

///|
fn wesl_source_has_explicit_int_literal(source : String) -> Bool {
  let mut index = 0
  while index < source.length() {
    let code = source.code_unit_at(index).to_int()
    if code == 47 &&
      index + 1 < source.length() &&
      source.code_unit_at(index + 1).to_int() == 47 {
      index += 2
      while index < source.length() && source.code_unit_at(index).to_int() != 10 {
        index += 1
      }
      continue
    }
    if code == 47 &&
      index + 1 < source.length() &&
      source.code_unit_at(index + 1).to_int() == 42 {
      index += 2
      while index + 1 < source.length() {
        if source.code_unit_at(index).to_int() == 42 &&
          source.code_unit_at(index + 1).to_int() == 47 {
          index += 2
          break
        }
        index += 1
      }
      continue
    }
    let digit_start = if code == 45 &&
      index + 1 < source.length() &&
      wesl_is_digit(source.code_unit_at(index + 1).to_int()) {
      index + 1
    } else if wesl_is_digit(code) {
      index
    } else {
      index += 1
      continue
    }
    let mut end_index = digit_start
    while end_index < source.length() &&
          wesl_is_digit(source.code_unit_at(end_index).to_int()) {
      end_index += 1
    }
    if end_index < source.length() &&
      source.code_unit_at(end_index).to_int() == 105 {
      let after = if end_index + 1 < source.length() {
        source.code_unit_at(end_index + 1).to_int()
      } else {
        -1
      }
      if after < 0 || !wesl_is_identifier_char(after) {
        return true
      }
    }
    index = end_index
  }
  false
}

///|
fn wesl_find_statement_end(
  tokens : Array[ParserToken],
  start_index : Int,
) -> Int {
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  let mut index = start_index
  while index < tokens.length() {
    match tokens[index] {
      LParen(_, _, _) => paren_depth += 1
      RParen(_, _, _) => if paren_depth > 0 { paren_depth -= 1 }
      LBracket(_, _, _) => bracket_depth += 1
      RBracket(_, _, _) => if bracket_depth > 0 { bracket_depth -= 1 }
      LBrace(_, _, _) => brace_depth += 1
      RBrace(_, _, _) =>
        if brace_depth == 0 {
          return index
        } else {
          brace_depth -= 1
        }
      Semi(_, _, _) if paren_depth == 0 &&
        bracket_depth == 0 &&
        brace_depth == 0 => return index
      _ => ()
    }
    index += 1
  }
  tokens.length()
}

///|
fn wesl_binding_is_matrix_type(
  source : String,
  tokens : Array[ParserToken],
  name_index : Int,
) -> Bool {
  let mut index = name_index + 1
  while index < tokens.length() {
    match tokens[index] {
      Other(_, _, _) if wesl_token_text(source, tokens[index]) == ":" => {
        let mut type_index = index + 1
        while type_index < tokens.length() {
          match tokens[type_index] {
            Ident(type_name, _, _, _) =>
              return wesl_is_matrix_type_name(type_name)
            Eq(_, _, _) => break
            Semi(_, _, _) => break
            _ => type_index += 1
          }
        }
      }
      Eq(_, _, _) => {
        let mut value_index = index + 1
        while value_index < tokens.length() {
          match tokens[value_index] {
            Ident(type_name, _, _, _) =>
              return wesl_is_matrix_type_name(type_name) &&
                value_index + 1 < tokens.length() &&
                tokens[value_index + 1] is LParen(_, _, _)
            Semi(_, _, _) => break
            _ => value_index += 1
          }
        }
      }
      Semi(_, _, _) => break
      _ => ()
    }
    index += 1
  }
  false
}

///|
fn wesl_validate_matrix_type_templates(
  path : ModulePath,
  item : ModuleItem,
) -> Unit raise WeslCompileError {
  let tokens = parser_lex(item.source)
  let context = wesl_item_context(path, item)
  for index in 0..<tokens.length() {
    match tokens[index] {
      Ident(type_name, _, _, _) =>
        if wesl_is_matrix_type_name(type_name) &&
          index + 1 < tokens.length() &&
          tokens[index + 1] is Lt(start_offset, end_offset, _) {
          let close_offset = wesl_find_matching_delim(
            item.source,
            start_offset,
            60,
            62,
          )
          let scalar = item.source[end_offset:close_offset]
            .to_string()
            .trim()
            .to_string()
          if scalar != "" && !wesl_is_float_scalar_name(scalar) {
            raise WeslCompileError::Validation(
              "matrix types must use floating scalar types (\{context})",
            )
          }
        }
      _ => ()
    }
  }
}

///|
fn wesl_validate_matrix_constructors(
  path : ModulePath,
  item : ModuleItem,
) -> Unit raise WeslCompileError {
  let tokens = parser_lex(item.source)
  let context = wesl_item_context(path, item)
  for index in 0..<tokens.length() {
    match tokens[index] {
      Ident(type_name, _, _, _) =>
        if wesl_is_matrix_type_name(type_name) &&
          index + 1 < tokens.length() &&
          tokens[index + 1] is LParen(start_offset, end_offset, _) {
          let close_offset = wesl_find_matching_delim(
            item.source,
            start_offset,
            40,
            41,
          )
          let arguments = item.source[end_offset:close_offset].to_string()
          if wesl_source_has_explicit_int_literal(arguments) {
            raise WeslCompileError::Validation(
              "matrix constructors must not use explicit integer literals (\{context})",
            )
          }
        }
      _ => ()
    }
  }
}

///|
fn wesl_validate_matrix_assignments(
  path : ModulePath,
  item : ModuleItem,
) -> Unit raise WeslCompileError {
  let tokens = parser_lex(item.source)
  let matrix_scopes : Array[Array[String]] = [[]]
  let mut scope_depth = 0
  let context = wesl_item_context(path, item)
  let mut index = 0
  while index < tokens.length() {
    match tokens[index] {
      LBrace(_, _, _) => {
        scope_depth += 1
        if scope_depth < matrix_scopes.length() {
          matrix_scopes[scope_depth] = []
        } else {
          matrix_scopes.push([])
        }
      }
      RBrace(_, _, _) => if scope_depth > 0 { scope_depth -= 1 }
      Ident(keyword, _, _, _) =>
        if keyword == "const" || keyword == "let" || keyword == "var" {
          match wesl_find_binding_name_index(tokens, index) {
            Some(name_index) =>
              match tokens[name_index] {
                Ident(name, _, _, _) =>
                  if wesl_binding_is_matrix_type(
                      item.source,
                      tokens,
                      name_index,
                    ) {
                    wesl_bind_scope(matrix_scopes, scope_depth, name)
                  }
                _ => ()
              }
            None => ()
          }
        } else if wesl_scopes_contain(matrix_scopes, scope_depth, keyword) {
          let mut lookahead = index + 1
          let mut saw_index_access = false
          while lookahead < tokens.length() {
            match tokens[lookahead] {
              LBracket(_, _, _) => {
                saw_index_access = true
                let mut bracket_depth = 1
                lookahead += 1
                while lookahead < tokens.length() {
                  match tokens[lookahead] {
                    LBracket(_, _, _) => bracket_depth += 1
                    RBracket(_, _, _) => {
                      bracket_depth -= 1
                      if bracket_depth == 0 {
                        lookahead += 1
                        break
                      }
                    }
                    _ => ()
                  }
                  lookahead += 1
                }
                continue
              }
              Eq(_, end_offset, _) if saw_index_access => {
                let rhs_end_index = wesl_find_statement_end(
                  tokens,
                  lookahead + 1,
                )
                let rhs_end_offset = if rhs_end_index < tokens.length() {
                  tokens[rhs_end_index].start()
                } else {
                  item.source.length()
                }
                let rhs = item.source[end_offset:rhs_end_offset].to_string()
                if wesl_source_has_explicit_int_literal(rhs) {
                  raise WeslCompileError::Validation(
                    "matrix assignments must not use explicit integer literals (\{context})",
                  )
                }
                break
              }
              _ => break
            }
          }
        }
      _ => ()
    }
    index += 1
  }
}

///|
fn wesl_validate_item_types(
  path : ModulePath,
  item : ModuleItem,
) -> Unit raise WeslCompileError {
  wesl_validate_matrix_type_templates(path, item)
  wesl_validate_matrix_constructors(path, item)
  wesl_validate_matrix_assignments(path, item)
}

///|
fn wesl_validate_loaded_types(
  order : Array[ModulePath],
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
) -> Unit raise WeslCompileError {
  for path in order {
    guard modules.get(path) is Some(parsed_module) else { continue }
    for item in parsed_module.items {
      ignore(wesl_validate_item_types(path, item))
    }
  }
}

///|
fn wesl_emit_item_source(
  parsed_module : ParsedModule,
  item : ModuleItem,
  root : ModulePath,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  used_decls : @hashmap.HashMap[String, Bool],
  mangler : EscapeMangler,
  options : CompileOptions,
) -> String {
  let mut current = item.source
  for reference in item.references {
    match reference {
      ModuleItemRef::Import(import_ref, import_index) => {
        let import_item = parsed_module.imports[import_index]
        match wesl_import_named_target(import_item) {
          Some((import_path, import_name)) => {
            let (target_path, target_name) = wesl_resolve_export_target(
              import_path, import_name, modules,
            ) catch {
              _ => (import_path, import_name)
            }
            current = wesl_replace_reference_identifier(
              current,
              import_ref,
              EscapeMangler::mangle(mangler, target_path, target_name),
              item.name,
            )
          }
          None => ()
        }
      }
      ModuleItemRef::Qualified(qualified_ref, target_path, target_name) =>
        current = wesl_replace_identifier(
          current,
          qualified_ref,
          EscapeMangler::mangle(mangler, target_path, target_name),
        )
      ModuleItemRef::Local(_) => ()
    }
  }
  if parsed_module.path != root || options.mangle_root {
    for entry in parsed_module.named_items.iter() {
      let (name, _) = entry
      if !options.strip ||
        wesl_is_used_decl(used_decls, parsed_module.path, name) {
        current = wesl_replace_global_identifier(
          current,
          name,
          EscapeMangler::mangle(mangler, parsed_module.path, name),
          item.name,
        )
      }
    }
  }
  current.trim().to_string()
}

///|
fn wesl_emit_module(
  path : ModulePath,
  root : ModulePath,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  used_modules : @hashmap.HashMap[ModulePath, Bool],
  used_decls : @hashmap.HashMap[String, Bool],
  emitted : @hashmap.HashMap[ModulePath, Bool],
  parts : Array[String],
  mangler : EscapeMangler,
  options : CompileOptions,
) -> Unit {
  if emitted.contains(path) || !used_modules.contains(path) {
    return
  }
  emitted.set(path, true)
  guard modules.get(path) is Some(parsed_module) else { return }
  if !options.strip || !options.lazy_resolution {
    for import_item in parsed_module.imports {
      match wesl_import_named_target(import_item) {
        Some((import_path, import_name)) =>
          try
            wesl_resolve_export_target(import_path, import_name, modules)
          catch {
            _ => ()
          } noraise {
            (target_path, _) =>
              wesl_emit_module(
                target_path, root, modules, used_modules, used_decls, emitted, parts,
                mangler, options,
              )
          }
        None => ()
      }
      wesl_emit_module(
        import_item.namespace_path,
        root,
        modules,
        used_modules,
        used_decls,
        emitted,
        parts,
        mangler,
        options,
      )
    }
  } else {
    for import_item in parsed_module.imports {
      if import_item.public &&
        wesl_is_used_decl(
          used_decls,
          parsed_module.path,
          import_item.local_name,
        ) {
        match wesl_import_named_target(import_item) {
          Some((import_path, import_name)) =>
            try
              wesl_resolve_export_target(import_path, import_name, modules)
            catch {
              _ => ()
            } noraise {
              (target_path, _) =>
                wesl_emit_module(
                  target_path, root, modules, used_modules, used_decls, emitted,
                  parts, mangler, options,
                )
            }
          None => ()
        }
      }
    }
    for item in parsed_module.items {
      let should_emit = match item.name {
        Some(name) => wesl_is_used_decl(used_decls, parsed_module.path, name)
        None => true
      }
      if !should_emit {
        continue
      }
      for reference in item.references {
        match reference {
          ModuleItemRef::Import(_, import_index) =>
            match
              wesl_import_named_target(parsed_module.imports[import_index]) {
              Some((import_path, import_name)) =>
                try
                  wesl_resolve_export_target(import_path, import_name, modules)
                catch {
                  _ => ()
                } noraise {
                  (target_path, _) =>
                    wesl_emit_module(
                      target_path, root, modules, used_modules, used_decls, emitted,
                      parts, mangler, options,
                    )
                }
              None => ()
            }
          ModuleItemRef::Qualified(_, target_path, _) =>
            wesl_emit_module(
              target_path, root, modules, used_modules, used_decls, emitted, parts,
              mangler, options,
            )
          ModuleItemRef::Local(_) => ()
        }
      }
    }
  }
  for item in parsed_module.items {
    let should_emit = match item.name {
      Some(name) =>
        if options.strip {
          wesl_is_used_decl(used_decls, parsed_module.path, name)
        } else {
          true
        }
      None => true
    }
    if !should_emit {
      continue
    }
    let emitted_item = wesl_emit_item_source(
      parsed_module, item, root, modules, used_decls, mangler, options,
    )
    if emitted_item != "" {
      parts.push(emitted_item)
    }
  }
}

///|
pub fn[R : Resolver] compile(
  root : ModulePath,
  resolver : R,
  mangler : EscapeMangler,
  options : CompileOptions,
) -> CompileResult raise WeslCompileError {
  let _ = options.lower
  let modules : @hashmap.HashMap[ModulePath, ParsedModule] = @hashmap.HashMap::new()
  let order : Array[ModulePath] = []
  let used_modules : @hashmap.HashMap[ModulePath, Bool] = @hashmap.HashMap::new()
  let used_decls : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let root_module = wesl_mark_module_used(
    root, resolver, options, modules, order, used_modules, used_decls,
  )
  wesl_validate_loaded_cycles(order, modules)
  wesl_validate_loaded_types(order, modules)
  for keep_name in wesl_root_keep_names(root_module, options) {
    ignore(
      wesl_mark_named_decl(
        root, keep_name, resolver, options, modules, order, used_modules, used_decls,
      ),
    )
  }
  if !options.strip {
    for module_path in order {
      used_modules.set(module_path, true)
    }
  }
  let emitted : @hashmap.HashMap[ModulePath, Bool] = @hashmap.HashMap::new()
  let parts : Array[String] = []
  wesl_emit_module(
    root, root, modules, used_modules, used_decls, emitted, parts, mangler, options,
  )
  let assembled = parts.filter(fn(part) { part != "" }).join("\n\n")
  CompileResult::{
    source: if options.lower {
      wesl_lower_source(assembled)
    } else {
      assembled
    },
    modules: order,
  }
}
