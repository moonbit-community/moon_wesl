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
fn cli_test_ensure_dir(path : String) -> Unit {
  if !@fs.path_exists(path) {
    try! @fs.create_dir(path)
  }
}

///|
test "wesl cli: help lists upstream command matrix" {
  let result = wesl_cli_run(["help"][:])
  inspect(result.status, content="0")
  assert_true(result.stdout.contains("check"))
  assert_true(result.stdout.contains("compile"))
  assert_true(result.stdout.contains("eval"))
  assert_true(result.stdout.contains("exec"))
  assert_true(result.stdout.contains("package"))
}

///|
test "wesl cli: eval expression without context" {
  let result = wesl_cli_run(["eval", "abs(3 - 5)"][:])
  inspect(result.status, content="0")
  inspect(result.stdout, content="2")
  inspect(result.stderr, content="")
}

///|
test "wesl cli: compile file with base and feature flags" {
  cli_test_ensure_dir("_build")
  cli_test_ensure_dir("_build/cli_compile")
  try! @fs.write_string_to_file(
    "_build/cli_compile/main.wesl", "@if(foo)\nfn enabled() -> i32 { return 1; }\n@else\nfn disabled() -> i32 { return 0; }\n",
  )
  let result = wesl_cli_run(
    [
      "compile", "--base", "_build/cli_compile", "--no-strip", "-D", "foo=true",
      "_build/cli_compile/main.wesl",
    ][:],
  )
  inspect(result.status, content="0")
  assert_true(result.stdout.contains("fn enabled"))
  assert_false(result.stdout.contains("fn disabled"))
}

///|
test "wesl cli: package emits scanned codegen artifact" {
  cli_test_ensure_dir("_build")
  cli_test_ensure_dir("_build/cli_package")
  try! @fs.write_string_to_file(
    "_build/cli_package/lib.wesl", "fn exported() -> i32 { return 1; }\n",
  )
  let result = wesl_cli_run(
    ["package", "shader-lib", "_build/cli_package/lib"][:],
  )
  inspect(result.status, content="0")
  assert_true(result.stdout.contains("CodegenPkg::"))
  assert_true(result.stdout.contains("shader_lib"))
}

///|
test "wesl cli: exec advertises current runtime gap" {
  let result = wesl_cli_run(["exec", "--entrypoint", "main"][:])
  inspect(result.status, content="1")
  assert_true(result.stderr.contains("CPU execution"))
}
