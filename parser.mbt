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
priv enum ParserToken {
  At(Int, Int, Int)
  LParen(Int, Int, Int)
  RParen(Int, Int, Int)
  LBrace(Int, Int, Int)
  RBrace(Int, Int, Int)
  LBracket(Int, Int, Int)
  RBracket(Int, Int, Int)
  Comma(Int, Int, Int)
  Semi(Int, Int, Int)
  Eq(Int, Int, Int)
  Lt(Int, Int, Int)
  Gt(Int, Int, Int)
  DoubleColon(Int, Int, Int)
  Ident(String, Int, Int, Int)
  Other(Int, Int, Int)
}

///|
fn ParserToken::start(self : ParserToken) -> Int {
  match self {
    At(start, _, _) => start
    LParen(start, _, _) => start
    RParen(start, _, _) => start
    LBrace(start, _, _) => start
    RBrace(start, _, _) => start
    LBracket(start, _, _) => start
    RBracket(start, _, _) => start
    Comma(start, _, _) => start
    Semi(start, _, _) => start
    Eq(start, _, _) => start
    Lt(start, _, _) => start
    Gt(start, _, _) => start
    DoubleColon(start, _, _) => start
    Ident(_, start, _, _) => start
    Other(start, _, _) => start
  }
}

///|
fn ParserToken::end(self : ParserToken) -> Int {
  match self {
    At(_, end_, _) => end_
    LParen(_, end_, _) => end_
    RParen(_, end_, _) => end_
    LBrace(_, end_, _) => end_
    RBrace(_, end_, _) => end_
    LBracket(_, end_, _) => end_
    RBracket(_, end_, _) => end_
    Comma(_, end_, _) => end_
    Semi(_, end_, _) => end_
    Eq(_, end_, _) => end_
    Lt(_, end_, _) => end_
    Gt(_, end_, _) => end_
    DoubleColon(_, end_, _) => end_
    Ident(_, _, end_, _) => end_
    Other(_, end_, _) => end_
  }
}

///|
fn ParserToken::line(self : ParserToken) -> Int {
  match self {
    At(_, _, line) => line
    LParen(_, _, line) => line
    RParen(_, _, line) => line
    LBrace(_, _, line) => line
    RBrace(_, _, line) => line
    LBracket(_, _, line) => line
    RBracket(_, _, line) => line
    Comma(_, _, line) => line
    Semi(_, _, line) => line
    Eq(_, _, line) => line
    Lt(_, _, line) => line
    Gt(_, _, line) => line
    DoubleColon(_, _, line) => line
    Ident(_, _, _, line) => line
    Other(_, _, line) => line
  }
}

///|
fn parser_is_identifier_start(code : Int) -> Bool {
  (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || code == 95
}

///|
fn parser_is_identifier_char(code : Int) -> Bool {
  parser_is_identifier_start(code) || (code >= 48 && code <= 57)
}

///|
fn parser_is_reserved_word(name : String) -> Bool {
  match name {
    "alias" => true
    "await" => true
    "break" => true
    "case" => true
    "common" => true
    "const" => true
    "const_assert" => true
    "continue" => true
    "continuing" => true
    "default" => true
    "diagnostic" => true
    "discard" => true
    "else" => true
    "enable" => true
    "export" => true
    "false" => true
    "fn" => true
    "for" => true
    "if" => true
    "import" => true
    "let" => true
    "loop" => true
    "NULL" => true
    "of" => true
    "override" => true
    "package" => true
    "requires" => true
    "return" => true
    "self" => true
    "struct" => true
    "super" => true
    "switch" => true
    "true" => true
    "var" => true
    "wgsl" => true
    "while" => true
    _ => false
  }
}

///|
fn parser_validate_declaration_ident(
  name : String,
) -> Unit raise WeslCompileError {
  if name == "_" {
    raise WeslCompileError::Parse("invalid declaration identifier `\{name}`")
  }
  if name.length() >= 2 && name[:2].to_owned() == "__" {
    raise WeslCompileError::Parse("invalid declaration identifier `\{name}`")
  }
  if parser_is_reserved_word(name) {
    raise WeslCompileError::Parse("invalid declaration identifier `\{name}`")
  }
}

///|
fn parser_lex(source : String) -> Array[ParserToken] {
  let tokens : Array[ParserToken] = []
  let mut index = 0
  let mut line = 1
  while index < source.length() {
    let code = source.code_unit_at(index).to_int()
    if code == 32 || code == 9 || code == 13 {
      index += 1
      continue
    }
    if code == 10 {
      line += 1
      index += 1
      continue
    }
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
        if source.code_unit_at(index).to_int() == 10 {
          line += 1
        }
        if source.code_unit_at(index).to_int() == 42 &&
          source.code_unit_at(index + 1).to_int() == 47 {
          index += 2
          break
        }
        index += 1
      }
      continue
    }
    if code == 58 &&
      index + 1 < source.length() &&
      source.code_unit_at(index + 1).to_int() == 58 {
      tokens.push(DoubleColon(index, index + 2, line))
      index += 2
      continue
    }
    if parser_is_identifier_start(code) {
      let start = index
      index += 1
      while index < source.length() &&
            parser_is_identifier_char(source.code_unit_at(index).to_int()) {
        index += 1
      }
      tokens.push(Ident(source[start:index].to_owned(), start, index, line))
      continue
    }
    match code {
      64 => tokens.push(At(index, index + 1, line))
      40 => tokens.push(LParen(index, index + 1, line))
      41 => tokens.push(RParen(index, index + 1, line))
      123 => tokens.push(LBrace(index, index + 1, line))
      125 => tokens.push(RBrace(index, index + 1, line))
      91 => tokens.push(LBracket(index, index + 1, line))
      93 => tokens.push(RBracket(index, index + 1, line))
      44 => tokens.push(Comma(index, index + 1, line))
      59 => tokens.push(Semi(index, index + 1, line))
      61 => tokens.push(Eq(index, index + 1, line))
      60 => tokens.push(Lt(index, index + 1, line))
      62 => tokens.push(Gt(index, index + 1, line))
      _ => tokens.push(Other(index, index + 1, line))
    }
    index += 1
  }
  tokens
}

///|
fn[T] ArrayView::start(self : ArrayView[T]) -> Int = "%arrayview.start"

///|
priv struct Parser {
  source : String
  tokens : Array[ParserToken]
  mut position : Int
}

///|
fn Parser::new(source : String) -> Parser {
  Parser::{ source, tokens: parser_lex(source), position: 0 }
}

///|
fn Parser::from_view(source : String, view : ArrayView[ParserToken]) -> Parser {
  let tokens : Array[ParserToken] = []
  for token in view {
    tokens.push(token)
  }
  Parser::{ source, tokens, position: 0 }
}

///|
fn Parser::view(self : Parser) -> ArrayView[ParserToken] {
  self.tokens[self.position:]
}

///|
fn Parser::update_view(self : Parser, view : ArrayView[ParserToken]) -> Unit {
  self.position = view.start()
}

///|
fn[A] Parser::error(
  self : Parser,
  message : String,
) -> A raise WeslCompileError {
  match self.view() {
    [token, ..] =>
      raise WeslCompileError::Parse("\{message} at line \{token.line()}")
    [] => raise WeslCompileError::Parse("\{message} at the end of input")
  }
}

///|
fn Parser::source_slice(
  self : Parser,
  start_offset : Int,
  end_offset : Int,
) -> String {
  if start_offset >= end_offset {
    ""
  } else {
    self.source[start_offset:end_offset].to_owned()
  }
}

///|
fn Parser::trim_source_slice(
  self : Parser,
  start_offset : Int,
  end_offset : Int,
) -> String {
  self.source_slice(start_offset, end_offset).trim().to_owned()
}

///|
fn Parser::item_source(self : Parser) -> String raise WeslCompileError {
  match self.tokens[:] {
    [first, ..] =>
      match self.tokens.last() {
        Some(last) => self.source_slice(first.start(), last.end())
        None => self.error("empty top-level item")
      }
    [] => self.error("empty top-level item")
  }
}

///|
fn Parser::item_span(self : Parser) -> SyntaxSpan raise WeslCompileError {
  match self.tokens[:] {
    [first, ..] =>
      match self.tokens.last() {
        Some(last) =>
          SyntaxSpan::{ start_line: first.line(), end_line: last.line() }
        None => self.error("empty top-level item")
      }
    [] => self.error("empty top-level item")
  }
}

///|
fn Parser::consume_balanced_parens(
  self : Parser,
) -> ParserToken raise WeslCompileError {
  let mut depth = 1
  let rest = for current = self.view() {
    match current {
      [token, .. rest] =>
        match token {
          LParen(_, _, _) => {
            depth += 1
            continue rest
          }
          RParen(_, _, _) => {
            depth -= 1
            if depth == 0 {
              break rest
            }
            continue rest
          }
          _ => continue rest
        }
      [] => self.error("unclosed attribute arguments")
    }
  }
  let closing_index = rest.start() - 1
  let closing_token = self.tokens[closing_index]
  self.update_view(rest)
  closing_token
}

///|
fn Parser::consume_balanced_angles(
  self : Parser,
) -> ParserToken raise WeslCompileError {
  let mut depth = 1
  let rest = for current = self.view() {
    match current {
      [token, .. rest] =>
        match token {
          Lt(_, _, _) => {
            depth += 1
            continue rest
          }
          Gt(_, _, _) => {
            depth -= 1
            if depth == 0 {
              break rest
            }
            continue rest
          }
          _ => continue rest
        }
      [] => self.error("unclosed generic arguments")
    }
  }
  let closing_index = rest.start() - 1
  let closing_token = self.tokens[closing_index]
  self.update_view(rest)
  closing_token
}

///|
fn Parser::parse_attributes(
  self : Parser,
) -> Array[Attribute] raise WeslCompileError {
  let attrs : Array[Attribute] = []
  for current = self.view() {
    match current {
      [At(_, _, _) as at_token, Ident(name, _, _, _), .. rest] => {
        self.update_view(rest)
        match self.view() {
          [LParen(_, _, _) as lparen_token, .. after_lparen] => {
            self.update_view(after_lparen)
            let closing_token = self.consume_balanced_parens()
            attrs.push(Attribute::{
              name,
              arguments: Some(
                self.trim_source_slice(
                  lparen_token.end(),
                  closing_token.start(),
                ),
              ),
              span: SyntaxSpan::{
                start_line: at_token.line(),
                end_line: closing_token.line(),
              },
            })
            continue self.view()
          }
          _ => {
            attrs.push(Attribute::{
              name,
              arguments: None,
              span: SyntaxSpan::{
                start_line: at_token.line(),
                end_line: at_token.line(),
              },
            })
            continue self.view()
          }
        }
      }
      rest => {
        self.update_view(rest)
        break
      }
    }
  }
  attrs
}

///|
fn Parser::item_is_import(self : Parser) -> Bool raise WeslCompileError {
  ignore(self.parse_attributes())
  match self.view() {
    [Ident("import", _, _, _), ..] => true
    _ => false
  }
}

///|
fn Parser::consume_top_level_item(
  self : Parser,
) -> ArrayView[ParserToken] raise WeslCompileError {
  let view = self.view()
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  let mut saw_brace = false
  let rest = for current = view {
    match current {
      [LParen(_, _, _), .. rest] => {
        paren_depth += 1
        continue rest
      }
      [RParen(_, _, _), .. rest] => {
        paren_depth -= 1
        continue rest
      }
      [LBracket(_, _, _), .. rest] => {
        bracket_depth += 1
        continue rest
      }
      [RBracket(_, _, _), .. rest] => {
        bracket_depth -= 1
        continue rest
      }
      [LBrace(_, _, _), .. rest] => {
        brace_depth += 1
        saw_brace = true
        continue rest
      }
      [RBrace(_, _, _), .. rest] => {
        brace_depth -= 1
        if paren_depth == 0 &&
          bracket_depth == 0 &&
          brace_depth == 0 &&
          saw_brace {
          match rest {
            [Semi(_, _, _), ..] => continue rest
            _ => break rest
          }
        }
        continue rest
      }
      [Semi(_, _, _), .. rest] if paren_depth == 0 &&
        bracket_depth == 0 &&
        brace_depth == 0 => break rest
      [_, .. rest] => continue rest
      [] => self.error("unexpected end of top-level item")
    }
  }
  let consumed = view.length() - rest.length()
  let item = view[:consumed]
  self.update_view(rest)
  item
}

///|
fn Parser::parse_import_segment(self : Parser) -> String raise WeslCompileError {
  match self.view() {
    [Ident("as", _, _, _), ..] => self.error("expected import path segment")
    [Ident(segment, _, _, _), .. rest] => {
      self.update_view(rest)
      segment
    }
    _ => self.error("expected import path segment")
  }
}

///|
fn Parser::parse_import_group(
  self : Parser,
  entries : Array[ImportNode],
) -> Unit raise WeslCompileError {
  if self.view() is [RBrace(_, _, _), ..] {
    self.error("import group must not be empty")
  }
  while true {
    entries.push(self.parse_import_node())
    match self.view() {
      [Comma(_, _, _), .. rest] => {
        self.update_view(rest)
        if self.view() is [RBrace(_, _, _), ..] {
          return
        }
      }
      [RBrace(_, _, _), ..] => return
      _ => self.error("expected ',' or '}' in import group")
    }
  }
}

///|
fn Parser::parse_import_node(
  self : Parser,
) -> ImportNode raise WeslCompileError {
  match self.view() {
    [LBrace(_, _, _), ..] => self.error("unexpected anonymous import group")
    _ => {
      let segments : Array[String] = []
      segments.push(self.parse_import_segment())
      while true {
        match self.view() {
          [DoubleColon(_, _, _), LBrace(_, _, _), .. rest] => {
            self.update_view(rest)
            let children : Array[ImportNode] = []
            self.parse_import_group(children)
            match self.view() {
              [RBrace(_, _, _), .. tail] => {
                self.update_view(tail)
                return ImportNode::{
                  path_segments: segments,
                  rename: None,
                  children,
                }
              }
              _ => self.error("expected '}' after import group")
            }
          }
          [DoubleColon(_, _, _), .. rest] => {
            self.update_view(rest)
            segments.push(self.parse_import_segment())
          }
          _ => break
        }
      }
      let local_name = match self.view() {
        [Ident("as", _, _, _), Ident(alias_name, _, _, _), .. rest] => {
          self.update_view(rest)
          Some(alias_name)
        }
        [Ident("as", _, _, _), ..] =>
          self.error("expected import alias after `as`")
        _ => None
      }
      ImportNode::{ path_segments: segments, rename: local_name, children: [] }
    }
  }
}

///|
fn Parser::parse_import_statement(
  self : Parser,
  current_path : ModulePath,
) -> ImportStatement raise WeslCompileError {
  let item_source = self.item_source().trim().to_owned()
  let span = self.item_span()
  let context = span.context(current_path)
  guard self.tokens.last() is Some(Semi(_, _, _)) else {
    raise WeslCompileError::Parse(
      "unsupported import statement (\{context}): \{item_source}",
    )
  }
  let attrs = self.parse_attributes() catch {
    Parse(reason) => raise WeslCompileError::Parse("\{reason} (\{context})")
    err => raise err
  }
  guard self.view() is [Ident("import", _, _, _), .. after_import] else {
    raise WeslCompileError::Parse(
      "unsupported import statement (\{context}): \{item_source}",
    )
  }
  self.update_view(after_import)
  let items : Array[ImportNode] = []
  match self.view() {
    [LBrace(_, _, _), .. rest] => {
      self.update_view(rest)
      self.parse_import_group(items) catch {
        Parse(reason) => raise WeslCompileError::Parse("\{reason} (\{context})")
        err => raise err
      }
      match self.view() {
        [RBrace(_, _, _), .. tail] => self.update_view(tail)
        _ =>
          raise WeslCompileError::Parse(
            "unsupported import statement (\{context}): \{item_source}",
          )
      }
    }
    _ => ()
  }
  while true {
    match self.view() {
      [Semi(_, _, _), ..] => break
      [] =>
        raise WeslCompileError::Parse(
          "unsupported import statement (\{context}): \{item_source}",
        )
      _ =>
        items.push(
          self.parse_import_node() catch {
            Parse(reason) =>
              raise WeslCompileError::Parse("\{reason} (\{context})")
            err => raise err
          },
        )
    }
    match self.view() {
      [Comma(_, _, _), .. rest] => self.update_view(rest)
      [Semi(_, _, _), ..] => break
      _ =>
        raise WeslCompileError::Parse(
          "unsupported import statement (\{context}): \{item_source}",
        )
    }
  }
  if items.is_empty() {
    raise WeslCompileError::Parse(
      "unsupported import statement (\{context}): \{item_source}",
    )
  }
  let statement = ImportStatement::{ span, attributes: attrs, entries: items }
  ignore(statement.flatten_items(current_path))
  statement
}

///|
fn Parser::slice_after_top_level_eq(self : Parser) -> String? {
  guard self.tokens.last() is Some(last_token) else { return None }
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  let mut eq_end : Int? = None
  for current = self.tokens[:] {
    match current {
      [token, .. rest] => {
        match token {
          LParen(_, _, _) => paren_depth += 1
          RParen(_, _, _) => paren_depth -= 1
          LBracket(_, _, _) => bracket_depth += 1
          RBracket(_, _, _) => bracket_depth -= 1
          LBrace(_, _, _) => brace_depth += 1
          RBrace(_, _, _) => brace_depth -= 1
          Eq(_, end_, _) if paren_depth == 0 &&
            bracket_depth == 0 &&
            brace_depth == 0 => {
            eq_end = Some(end_)
            break
          }
          _ => ()
        }
        continue rest
      }
      [] => break
    }
  }
  match eq_end {
    Some(eq_offset) =>
      Some(
        self.trim_source_slice(
          eq_offset,
          match last_token {
            Semi(start, _, _) => start
            _ => last_token.end()
          },
        ),
      )
    None => None
  }
}

///|
fn Parser::parse_var_declaration(
  self : Parser,
) -> VarDeclaration raise WeslCompileError {
  let mut template_arguments : String? = None
  match self.view() {
    [Lt(_, _, _) as lt_token, .. rest] => {
      self.update_view(rest)
      let closing_token = self.consume_balanced_angles()
      template_arguments = Some(
        self.trim_source_slice(lt_token.end(), closing_token.start()),
      )
    }
    _ => ()
  }
  let name = match self.view() {
    [Ident(ident_name, _, _, _), .. rest] => {
      parser_validate_declaration_ident(ident_name)
      self.update_view(rest)
      Some(ident_name)
    }
    _ => None
  }
  VarDeclaration::{ name, template_arguments }
}

///|
fn Parser::parse_global_declaration(
  self : Parser,
) -> GlobalDeclaration raise WeslCompileError {
  let span = self.item_span()
  let item_source = self.item_source().trim().to_owned()
  let attrs = self.parse_attributes()
  let header = match self.view() {
    [Ident("fn", _, _, _), Ident(name, _, _, _), ..] => {
      parser_validate_declaration_ident(name)
      GlobalDeclarationHeader::Function(FunctionDeclaration::{ name, })
    }
    [Ident("struct", _, _, _), Ident(name, _, _, _), ..] => {
      parser_validate_declaration_ident(name)
      GlobalDeclarationHeader::Struct(StructDeclaration::{ name, })
    }
    [Ident("alias", _, _, _), Ident(name, _, _, _), ..] => {
      parser_validate_declaration_ident(name)
      GlobalDeclarationHeader::Alias(AliasDeclaration::{
        name,
        target: self.slice_after_top_level_eq(),
      })
    }
    [Ident("const", _, _, _), Ident(name, _, _, _), ..] => {
      parser_validate_declaration_ident(name)
      GlobalDeclarationHeader::Const(ConstDeclaration::{
        name,
        initializer: self.slice_after_top_level_eq(),
      })
    }
    [Ident("override", _, _, _), Ident(name, _, _, _), ..] => {
      parser_validate_declaration_ident(name)
      GlobalDeclarationHeader::Override(OverrideDeclaration::{ name, })
    }
    [Ident("let", _, _, _), Ident(name, _, _, _), ..] => {
      parser_validate_declaration_ident(name)
      GlobalDeclarationHeader::Let(LetDeclaration::{ name, })
    }
    [Ident("var", _, _, _), .. rest] => {
      self.update_view(rest)
      GlobalDeclarationHeader::Var(self.parse_var_declaration())
    }
    [Ident("const_assert", _, _, _), ..] => GlobalDeclarationHeader::ConstAssert
    _ => GlobalDeclarationHeader::Other
  }
  GlobalDeclaration::{ header, attributes: attrs, source: item_source, span }
}

///|
fn parse_global_declarations(
  source : String,
) -> Array[GlobalDeclaration] raise WeslCompileError {
  let declarations : Array[GlobalDeclaration] = []
  let parser = Parser::new(source)
  while !parser.view().is_empty() {
    let item_tokens = parser.consume_top_level_item()
    if Parser::from_view(source, item_tokens).item_is_import() {
      continue
    }
    declarations.push(
      Parser::from_view(source, item_tokens).parse_global_declaration(),
    )
  }
  declarations
}

///|
fn parse_translation_unit(
  current_path : ModulePath,
  source : String,
  parse_imports : Bool,
) -> TranslationUnit raise WeslCompileError {
  let imports : Array[ImportStatement] = []
  let global_declarations : Array[GlobalDeclaration] = []
  let parser = Parser::new(source)
  while !parser.view().is_empty() {
    let item_tokens = parser.consume_top_level_item()
    if Parser::from_view(source, item_tokens).item_is_import() {
      if parse_imports {
        imports.push(
          Parser::from_view(source, item_tokens).parse_import_statement(
            current_path,
          ),
        )
      }
      continue
    }
    global_declarations.push(
      Parser::from_view(source, item_tokens).parse_global_declaration(),
    )
  }
  TranslationUnit::{ imports, global_declarations }
}
