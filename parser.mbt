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
      tokens.push(Ident(source[start:index].to_string(), start, index, line))
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
fn parser_source_slice(
  source : String,
  start_offset : Int,
  end_offset : Int,
) -> String {
  if start_offset >= end_offset {
    ""
  } else {
    source[start_offset:end_offset].to_string()
  }
}

///|
fn parser_trim_source_slice(
  source : String,
  start_offset : Int,
  end_offset : Int,
) -> String {
  parser_source_slice(source, start_offset, end_offset).trim().to_string()
}

///|
fn parser_item_source(
  source : String,
  tokens : ArrayView[ParserToken],
) -> String raise WeslCompileError {
  match tokens {
    [first, ..] =>
      match tokens.last() {
        Some(last) => parser_source_slice(source, first.start(), last.end())
        None => raise WeslCompileError::Parse("empty top-level item")
      }
    [] => raise WeslCompileError::Parse("empty top-level item")
  }
}

///|
fn parser_item_span(
  tokens : ArrayView[ParserToken],
) -> SyntaxSpan raise WeslCompileError {
  match tokens {
    [first, ..] =>
      match tokens.last() {
        Some(last) =>
          SyntaxSpan::{ start_line: first.line(), end_line: last.line() }
        None => raise WeslCompileError::Parse("empty top-level item")
      }
    [] => raise WeslCompileError::Parse("empty top-level item")
  }
}

///|
fn parser_consume_balanced_parens(
  view : ArrayView[ParserToken],
) -> (ArrayView[ParserToken], ParserToken) raise WeslCompileError {
  let mut depth = 1
  for current = view {
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
              break (rest, token)
            }
            continue rest
          }
          _ => continue rest
        }
      [] => raise WeslCompileError::Parse("unclosed attribute arguments")
    }
  }
}

///|
fn parser_consume_balanced_angles(
  view : ArrayView[ParserToken],
) -> (ArrayView[ParserToken], ParserToken) raise WeslCompileError {
  let mut depth = 1
  for current = view {
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
              break (rest, token)
            }
            continue rest
          }
          _ => continue rest
        }
      [] => raise WeslCompileError::Parse("unclosed generic arguments")
    }
  }
}

///|
fn parser_parse_attributes(
  source : String,
  tokens : ArrayView[ParserToken],
) -> (Array[Attribute], ArrayView[ParserToken]) raise WeslCompileError {
  let attrs : Array[Attribute] = []
  let rest = for current = tokens {
    match current {
      [at_token, Ident(name, _, _, _), .. rest] => {
        guard at_token is At(_, _, _) else { break current }
        match rest {
          [lparen_token, .. after_lparen] =>
            if lparen_token is LParen(_, _, _) {
              let (after_args, closing_token) = parser_consume_balanced_parens(
                after_lparen,
              )
              attrs.push(Attribute::{
                name,
                arguments: Some(
                  parser_trim_source_slice(
                    source,
                    lparen_token.end(),
                    closing_token.start(),
                  ),
                ),
                span: SyntaxSpan::{
                  start_line: at_token.line(),
                  end_line: closing_token.line(),
                },
              })
              continue after_args
            } else {
              attrs.push(Attribute::{
                name,
                arguments: None,
                span: SyntaxSpan::{
                  start_line: at_token.line(),
                  end_line: at_token.line(),
                },
              })
              continue rest
            }
          [] => {
            attrs.push(Attribute::{
              name,
              arguments: None,
              span: SyntaxSpan::{
                start_line: at_token.line(),
                end_line: at_token.line(),
              },
            })
            continue rest
          }
        }
      }
      rest => break rest
    }
  }
  (attrs, rest)
}

///|
fn parser_item_is_import(
  source : String,
  tokens : ArrayView[ParserToken],
) -> Bool raise WeslCompileError {
  let (_, rest) = parser_parse_attributes(source, tokens)
  match rest {
    [Ident("import", _, _, _), ..] => true
    _ => false
  }
}

///|
fn parser_consume_top_level_item(
  view : ArrayView[ParserToken],
) -> (ArrayView[ParserToken], ArrayView[ParserToken]) raise WeslCompileError {
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
      [] => raise WeslCompileError::Parse("unexpected end of top-level item")
    }
  }
  let consumed = view.length() - rest.length()
  (view[:consumed], rest)
}

///|
fn parser_parse_import_segment(
  source : String,
  view : ArrayView[ParserToken],
) -> (String, ArrayView[ParserToken]) raise WeslCompileError {
  match view {
    [Ident("as", _, _, _), ..] =>
      raise WeslCompileError::Parse("expected import path segment")
    [Ident(segment, _, _, _), .. rest] => (segment, rest)
    _ => raise WeslCompileError::Parse("expected import path segment")
  }
}

///|
fn parser_parse_import_group(
  source : String,
  view : ArrayView[ParserToken],
  entries : Array[ImportNode],
) -> ArrayView[ParserToken] raise WeslCompileError {
  if view is [RBrace(_, _, _), ..] {
    raise WeslCompileError::Parse("import group must not be empty")
  }
  let mut current = view
  while true {
    let (entry, rest) = parser_parse_import_node(source, current)
    entries.push(entry)
    current = rest
    match current {
      [Comma(_, _, _), .. rest] => {
        current = rest
        if current is [RBrace(_, _, _), ..] {
          return current
        }
      }
      [RBrace(_, _, _), ..] => return current
      _ => raise WeslCompileError::Parse("expected ',' or '}' in import group")
    }
  }
  current
}

///|
fn parser_parse_import_node(
  source : String,
  view : ArrayView[ParserToken],
) -> (ImportNode, ArrayView[ParserToken]) raise WeslCompileError {
  match view {
    [LBrace(_, _, _), ..] =>
      raise WeslCompileError::Parse("unexpected anonymous import group")
    _ => {
      let segments : Array[String] = []
      let mut current = view
      let (first_segment, first_rest) = parser_parse_import_segment(
        source, current,
      )
      segments.push(first_segment)
      current = first_rest
      while true {
        match current {
          [DoubleColon(_, _, _), LBrace(_, _, _), .. rest] => {
            let children : Array[ImportNode] = []
            let inner_rest = parser_parse_import_group(source, rest, children)
            return match inner_rest {
              [RBrace(_, _, _), .. tail] =>
                (
                  ImportNode::{
                    path_segments: segments,
                    rename: None,
                    children,
                  },
                  tail,
                )
              _ =>
                raise WeslCompileError::Parse("expected '}' after import group")
            }
          }
          [DoubleColon(_, _, _), .. rest] => {
            let (segment, tail) = parser_parse_import_segment(source, rest)
            segments.push(segment)
            current = tail
          }
          _ => break
        }
      }
      let mut local_name : String? = None
      match current {
        [Ident("as", _, _, _), Ident(alias_name, _, _, _), .. rest] => {
          local_name = Some(alias_name)
          current = rest
        }
        [Ident("as", _, _, _), ..] =>
          raise WeslCompileError::Parse("expected import alias after `as`")
        _ => ()
      }
      (
        ImportNode::{
          path_segments: segments,
          rename: local_name,
          children: [],
        },
        current,
      )
    }
  }
}

///|
fn parser_parse_import_statement(
  current_path : ModulePath,
  source : String,
  tokens : ArrayView[ParserToken],
) -> ImportStatement raise WeslCompileError {
  let item_source = parser_item_source(source, tokens).trim().to_string()
  let span = parser_item_span(tokens)
  let context = span.context(current_path)
  guard tokens.last() is Some(Semi(_, _, _)) else {
    raise WeslCompileError::Parse(
      "unsupported import statement (\{context}): \{item_source}",
    )
  }
  let (attrs, rest) = parser_parse_attributes(source, tokens) catch {
    Parse(reason) => raise WeslCompileError::Parse("\{reason} (\{context})")
    err => raise err
  }
  guard rest is [Ident("import", _, _, _), .. after_import] else {
    raise WeslCompileError::Parse(
      "unsupported import statement (\{context}): \{item_source}",
    )
  }
  let items : Array[ImportNode] = []
  let mut current = after_import
  match current {
    [LBrace(_, _, _), .. rest] => {
      let inner_rest = parser_parse_import_group(source, rest, items) catch {
        Parse(reason) => raise WeslCompileError::Parse("\{reason} (\{context})")
        err => raise err
      }
      current = match inner_rest {
        [RBrace(_, _, _), .. tail] => tail
        _ =>
          raise WeslCompileError::Parse(
            "unsupported import statement (\{context}): \{item_source}",
          )
      }
    }
    _ => ()
  }
  while true {
    match current {
      [Semi(_, _, _), ..] => break
      [] =>
        raise WeslCompileError::Parse(
          "unsupported import statement (\{context}): \{item_source}",
        )
      _ => {
        let (entry, rest2) = parser_parse_import_node(source, current) catch {
          Parse(reason) =>
            raise WeslCompileError::Parse("\{reason} (\{context})")
          err => raise err
        }
        items.push(entry)
        current = rest2
      }
    }
    match current {
      [Comma(_, _, _), .. rest2] => current = rest2
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
fn parser_slice_after_top_level_eq(
  source : String,
  tokens : ArrayView[ParserToken],
) -> String? {
  guard tokens.last() is Some(last_token) else { return None }
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  let mut eq_end : Int? = None
  for current = tokens {
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
        parser_trim_source_slice(
          source,
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
fn parser_parse_var_declaration(
  source : String,
  view : ArrayView[ParserToken],
) -> VarDeclaration raise WeslCompileError {
  let mut current = view
  let mut template_arguments : String? = None
  match current {
    [lt_token, .. rest] =>
      if lt_token is Lt(_, _, _) {
        let (after_template, closing_token) = parser_consume_balanced_angles(
          rest,
        )
        template_arguments = Some(
          parser_trim_source_slice(
            source,
            lt_token.end(),
            closing_token.start(),
          ),
        )
        current = after_template
      }
    _ => ()
  }
  let name = match current {
    [Ident(ident_name, _, _, _), ..] => Some(ident_name)
    _ => None
  }
  VarDeclaration::{ name, template_arguments }
}

///|
fn parse_global_declaration(
  source : String,
  tokens : ArrayView[ParserToken],
) -> GlobalDeclaration raise WeslCompileError {
  let span = parser_item_span(tokens)
  let item_source = parser_item_source(source, tokens).trim().to_string()
  let (attrs, rest) = parser_parse_attributes(source, tokens)
  let header = match rest {
    [Ident("fn", _, _, _), Ident(name, _, _, _), ..] =>
      GlobalDeclarationHeader::Function(FunctionDeclaration::{ name, })
    [Ident("struct", _, _, _), Ident(name, _, _, _), ..] =>
      GlobalDeclarationHeader::Struct(StructDeclaration::{ name, })
    [Ident("alias", _, _, _), Ident(name, _, _, _), ..] =>
      GlobalDeclarationHeader::Alias(AliasDeclaration::{
        name,
        target: parser_slice_after_top_level_eq(source, tokens),
      })
    [Ident("const", _, _, _), Ident(name, _, _, _), ..] =>
      GlobalDeclarationHeader::Const(ConstDeclaration::{
        name,
        initializer: parser_slice_after_top_level_eq(source, tokens),
      })
    [Ident("override", _, _, _), Ident(name, _, _, _), ..] =>
      GlobalDeclarationHeader::Override(OverrideDeclaration::{ name, })
    [Ident("let", _, _, _), Ident(name, _, _, _), ..] =>
      GlobalDeclarationHeader::Let(LetDeclaration::{ name, })
    [Ident("var", _, _, _), .. rest] =>
      GlobalDeclarationHeader::Var(parser_parse_var_declaration(source, rest))
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
  let tokens = parser_lex(source)
  let mut view = tokens[:]
  while !view.is_empty() {
    let (item_tokens, rest) = parser_consume_top_level_item(view)
    view = rest
    if parser_item_is_import(source, item_tokens) {
      continue
    }
    declarations.push(parse_global_declaration(source, item_tokens))
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
  let tokens = parser_lex(source)
  let mut view = tokens[:]
  while !view.is_empty() {
    let (item_tokens, rest) = parser_consume_top_level_item(view)
    view = rest
    if parser_item_is_import(source, item_tokens) {
      if parse_imports {
        imports.push(
          parser_parse_import_statement(current_path, source, item_tokens),
        )
      }
      continue
    }
    global_declarations.push(parse_global_declaration(source, item_tokens))
  }
  TranslationUnit::{ imports, global_declarations }
}
