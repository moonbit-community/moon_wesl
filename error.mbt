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
pub(all) suberror WeslCompileError {
  Resolve(ResolveError)
  Parse(String)
  Validation(String)
  InvalidExpression(String)
  DuplicateSymbol(String)
  CircularDecl(String)
  MissingDecl(ModulePath, String)
  Private(String, ModulePath)
}

///|
pub fn WeslCompileError::message(self : WeslCompileError) -> String {
  match self {
    Resolve(err) => err.message()
    Parse(reason) => reason
    Validation(reason) => reason
    InvalidExpression(expr) => "invalid if attribute expression: `\{expr}`"
    DuplicateSymbol(symbol) => "duplicate declaration of `\{symbol}`"
    CircularDecl(symbol) => "circular declaration of `\{symbol}`"
    MissingDecl(path, item) =>
      "module `\{path.to_string()}` has no declaration `\{item}`"
    Private(item, path) =>
      "import of `\{item}` in module `\{path.to_string()}` is not `@publish`, but another module tried to import it"
  }
}
