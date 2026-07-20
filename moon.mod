name = "Milky2018/moon_wesl"

version = "0.1.2"

import {
  "moonbitlang/x@0.4.38",
}

readme = "README.md"

repository = "https://github.com/moonbit-community/moon_wesl"

license = "Apache-2.0"

keywords = [ "wesl", "shader" ]

description = "Deprecated standalone WESL compiler; moved to moon_wgsl/modules/moon_wesl."

options(
  "bin-deps": { "moonbitlang/yacc": "0.7.13" },
)
