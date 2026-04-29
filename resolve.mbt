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
pub(all) suberror ResolveError {
  FileNotFound(String, String)
  ModuleNotFound(ModulePath, String)
}

///|
pub fn ResolveError::message(self : ResolveError) -> String {
  match self {
    FileNotFound(path, context) => "file not found: `\{path}` (\{context})"
    ModuleNotFound(path, context) =>
      "module not found: `\{path.to_string()}` (\{context})"
  }
}

///|
pub(open) trait Resolver {
  resolve_source(Self, ModulePath) -> String raise ResolveError
  display_name(Self, ModulePath) -> String? = _
  fs_path(Self, ModulePath) -> String? = _
}

///|
impl Resolver with display_name(_self, _path) {
  None
}

///|
impl Resolver with fs_path(_self, _path) {
  None
}

///|
pub struct NoResolver {}

///|
pub fn NoResolver::new() -> NoResolver {
  NoResolver::{  }
}

///|
pub impl Resolver for NoResolver with resolve_source(_self, path) {
  raise ResolveError::ModuleNotFound(path, "no resolver")
}

///|
pub struct VirtualResolver {
  files : @hashmap.HashMap[ModulePath, String]
}

///|
pub fn VirtualResolver::new() -> VirtualResolver {
  VirtualResolver::{ files: @hashmap.HashMap::new() }
}

///|
pub fn VirtualResolver::add_module(
  self : VirtualResolver,
  path : ModulePath,
  source : String,
) -> Unit {
  self.files.set(path, source)
}

///|
pub fn VirtualResolver::get_module(
  self : VirtualResolver,
  path : ModulePath,
) -> String raise ResolveError {
  match self.files.get(path) {
    Some(source) => source
    None => raise ResolveError::ModuleNotFound(path, "virtual module")
  }
}

///|
pub fn VirtualResolver::modules(
  self : VirtualResolver,
) -> Array[(ModulePath, String)] {
  let modules : Array[(ModulePath, String)] = []
  for entry in self.files.iter() {
    modules.push(entry)
  }
  modules
}

///|
pub impl Resolver for VirtualResolver with resolve_source(self, path) {
  self.get_module(path)
}

///|
pub impl Resolver for VirtualResolver with display_name(_self, path) {
  Some(path.to_string())
}

///|
pub struct FileResolver {
  base : String
  extension : String
}

///|
pub fn FileResolver::new(base : String) -> FileResolver {
  FileResolver::{ base, extension: "wesl" }
}

///|
pub fn FileResolver::set_extension(
  self : FileResolver,
  extension : String,
) -> FileResolver {
  FileResolver::{ ..self, extension, }
}

///|
fn file_resolver_join(base : String, tail : String) -> String {
  if base == "" || base == "." {
    tail
  } else if base.has_suffix("/") {
    base + tail
  } else {
    base + "/" + tail
  }
}

///|
pub fn FileResolver::file_path(
  self : FileResolver,
  path : ModulePath,
) -> String raise ResolveError {
  if path.is_package() {
    raise ResolveError::ModuleNotFound(
      path, "this is an external package import, not a file import. Use `package::` or `super::` for file imports.",
    )
  }
  let tail = path.components.join("/")
  let stem = if tail == "" { "package" } else { tail }
  file_resolver_join(self.base, "\{stem}.\{self.extension}")
}

///|
pub impl Resolver for FileResolver with resolve_source(self, path) {
  let fs_path = self.file_path(path)
  raise ResolveError::FileNotFound(fs_path, "physical file")
}

///|
pub impl Resolver for FileResolver with display_name(self, path) {
  Some(self.file_path(path)) catch {
    _ => None
  }
}

///|
pub impl Resolver for FileResolver with fs_path(self, path) {
  Some(self.file_path(path)) catch {
    _ => None
  }
}

///|
pub struct StandardResolver {
  files : FileResolver
  constants : @hashmap.HashMap[String, Double]
}

///|
pub fn StandardResolver::new(base : String) -> StandardResolver {
  StandardResolver::{
    files: FileResolver::new(base),
    constants: @hashmap.HashMap::new(),
  }
}

///|
pub fn StandardResolver::add_constant(
  self : StandardResolver,
  name : String,
  value : Double,
) -> Unit {
  self.constants.set(name, value)
}

///|
pub fn StandardResolver::generate_constant_module(
  self : StandardResolver,
) -> String {
  let parts : Array[String] = []
  for entry in self.constants.iter() {
    let (name, value) = entry
    parts.push("const \{name} = \{value.to_string()};")
  }
  parts.join("\n")
}

///|
fn standard_resolver_is_constants_path(path : ModulePath) -> Bool {
  match path.origin {
    Package(name) => name == "constants" || name.has_suffix("/constants")
    _ => false
  }
}

///|
pub impl Resolver for StandardResolver with resolve_source(self, path) {
  if standard_resolver_is_constants_path(path) {
    self.generate_constant_module()
  } else {
    self.files.resolve_source(path)
  }
}

///|
pub impl Resolver for StandardResolver with display_name(self, path) {
  if standard_resolver_is_constants_path(path) {
    Some(path.to_string())
  } else {
    self.files.display_name(path)
  }
}

///|
pub impl Resolver for StandardResolver with fs_path(self, path) {
  if standard_resolver_is_constants_path(path) {
    None
  } else {
    self.files.fs_path(path)
  }
}

///|
priv enum ResolverMount {
  Virtual(VirtualResolver)
  File(FileResolver)
  Standard(StandardResolver)
}

///|
fn ResolverMount::resolve_source(
  self : ResolverMount,
  path : ModulePath,
) -> String raise ResolveError {
  match self {
    Virtual(resolver) => resolver.resolve_source(path)
    File(resolver) => resolver.resolve_source(path)
    Standard(resolver) => resolver.resolve_source(path)
  }
}

///|
fn ResolverMount::display_name(
  self : ResolverMount,
  path : ModulePath,
) -> String? {
  match self {
    Virtual(resolver) => resolver.display_name(path)
    File(resolver) => resolver.display_name(path)
    Standard(resolver) => resolver.display_name(path)
  }
}

///|
fn ResolverMount::fs_path(self : ResolverMount, path : ModulePath) -> String? {
  match self {
    Virtual(resolver) => resolver.fs_path(path)
    File(resolver) => resolver.fs_path(path)
    Standard(resolver) => resolver.fs_path(path)
  }
}

///|
pub struct Router {
  priv mount_points : Array[(ModulePath, ResolverMount)]
  priv mut fallback : (ModulePath, ResolverMount)?
}

///|
pub fn Router::new() -> Router {
  Router::{ mount_points: [], fallback: None }
}

///|
pub fn Router::mount_resolver(
  self : Router,
  prefix : ModulePath,
  resolver : VirtualResolver,
) -> Unit {
  self.mount_points.push((prefix, Virtual(resolver)))
}

///|
pub fn Router::mount_file_resolver(
  self : Router,
  prefix : ModulePath,
  resolver : FileResolver,
) -> Unit {
  self.mount_points.push((prefix, File(resolver)))
}

///|
pub fn Router::mount_standard_resolver(
  self : Router,
  prefix : ModulePath,
  resolver : StandardResolver,
) -> Unit {
  self.mount_points.push((prefix, Standard(resolver)))
}

///|
pub fn Router::mount_fallback_resolver(
  self : Router,
  resolver : VirtualResolver,
) -> Unit {
  self.fallback = Some((ModulePath::new_root(), Virtual(resolver)))
}

///|
pub fn Router::mount_fallback_file_resolver(
  self : Router,
  resolver : FileResolver,
) -> Unit {
  self.fallback = Some((ModulePath::new_root(), File(resolver)))
}

///|
fn router_suffix_path(path : ModulePath, prefix : ModulePath) -> ModulePath {
  ModulePath::new(
    Absolute,
    module_path_slice(
      path.components,
      prefix.components.length(),
      path.components.length(),
    ),
  )
}

///|
fn Router::route(
  self : Router,
  path : ModulePath,
) -> (ResolverMount, ModulePath) raise ResolveError {
  let mut selected : (ModulePath, ResolverMount)? = None
  for entry in self.mount_points {
    let (prefix, _) = entry
    if path.starts_with(prefix) {
      match selected {
        Some((best_prefix, _)) =>
          if prefix.components.length() > best_prefix.components.length() {
            selected = Some(entry)
          }
        None => selected = Some(entry)
      }
    }
  }
  match selected {
    Some((prefix, resolver)) => (resolver, router_suffix_path(path, prefix))
    None =>
      match self.fallback {
        Some((prefix, resolver)) => (resolver, router_suffix_path(path, prefix))
        None => raise ResolveError::ModuleNotFound(path, "no mount point")
      }
  }
}

///|
pub impl Resolver for Router with resolve_source(self, path) {
  let (resolver, suffix) = self.route(path)
  resolver.resolve_source(suffix)
}

///|
pub impl Resolver for Router with display_name(self, path) {
  try {
    let (resolver, suffix) = self.route(path)
    resolver.display_name(suffix)
  } catch {
    _ => None
  }
}

///|
pub impl Resolver for Router with fs_path(self, path) {
  try {
    let (resolver, suffix) = self.route(path)
    resolver.fs_path(suffix)
  } catch {
    _ => None
  }
}
