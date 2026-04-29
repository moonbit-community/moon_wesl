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
pub struct EscapeMangler {}

///|
pub(all) enum ManglerKind {
  Escape
  Hash
  Unicode
  None
} derive(Eq, Debug)

///|
pub fn EscapeMangler::default() -> EscapeMangler {
  EscapeMangler::{  }
}

///|
fn escape_mangler_count_char(text : String, ch : Int) -> Int {
  let mut count = 0
  for i in 0..<text.length() {
    if text.code_unit_at(i).to_int() == ch {
      count = count + 1
    }
  }
  count
}

///|
fn escape_mangler_component(comp : String) -> String {
  if comp.contains("/") {
    let count = escape_mangler_count_char(comp, 47) + 1
    let pieces : Array[String] = []
    for piece in comp.split("/") {
      pieces.push(escape_mangler_component(piece.to_owned()))
    }
    let suffix = pieces.join("_")
    return "import_\{count}_\{suffix}"
  }
  let underscores = escape_mangler_count_char(comp, 95)
  if underscores > 0 {
    "_\{underscores}\{comp}"
  } else {
    comp
  }
}

///|
pub fn EscapeMangler::mangle(
  _self : EscapeMangler,
  path : ModulePath,
  item : String,
) -> String {
  let origin = match path.origin {
    Absolute => "package"
    Relative(0) => "self"
    Relative(levels) => {
      let pieces : Array[String] = []
      for _ in 0..<levels {
        pieces.push("super")
      }
      pieces.join("_")
    }
    Package(name) => escape_mangler_component(name)
  }
  let escaped_item = escape_mangler_component(item)
  if path.components.length() == 0 {
    "\{origin}_\{escaped_item}"
  } else {
    let escaped_components : Array[String] = []
    for component in path.components {
      escaped_components.push(escape_mangler_component(component))
    }
    let escaped_path = escaped_components.join("_")
    "\{origin}_\{escaped_path}_\{escaped_item}"
  }
}

///|
fn hash_mangler_hash(path : ModulePath, item : String) -> UInt {
  let mut hash = 2166136261U
  let text = path.to_string() + "::" + item
  for index in 0..<text.length() {
    hash = hash ^ text.code_unit_at(index).to_uint()
    hash = hash * 16777619U
  }
  hash
}

///|
fn unicode_mangler_component(text : String) -> String {
  text
  .replace(old="_", new="＿")
  .replace(old="/", new="ᐟ")
  .replace(old=":", new="꞉")
  .replace(old="<", new="ᐸ")
  .replace(old=">", new="ᐳ")
  .replace(old=",", new="ˏ")
  .replace(old=" ", new="")
}

///|
pub fn ManglerKind::mangle(
  self : ManglerKind,
  path : ModulePath,
  item : String,
) -> String {
  match self {
    Escape => EscapeMangler::mangle(EscapeMangler::default(), path, item)
    Hash => "\{item}_\{hash_mangler_hash(path, item).to_string()}"
    Unicode =>
      if path.is_root() {
        unicode_mangler_component(item)
      } else {
        unicode_mangler_component(path.to_string()) +
        "_" +
        unicode_mangler_component(item)
      }
    None => item
  }
}
