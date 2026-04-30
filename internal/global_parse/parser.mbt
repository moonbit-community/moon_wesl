///|
pub suberror ParseError {
  UnexpectedToken(Token, (Int, Int), Array[TokenKind])
  UnexpectedEndOfInput(Int, Array[TokenKind])
} derive(Debug)

///|
type YYObj = Error

///|
priv suberror YYObj_Void

///|
priv suberror YYObj_Unit {
  YYObj_Unit(Unit)
}

///|
priv suberror YYObj_String {
  YYObj_String(String)
}

///|
priv suberror YYObj_GlobalParseHeader {
  YYObj_GlobalParseHeader(GlobalParseHeader)
}

///|
priv suberror YYObj_String_ {
  YYObj_String_(String?)
}

///|
type YYState = (YYSymbol) -> YYDecision

///|
type YYAction = (Int, ArrayView[(YYObj, Int, Int)]) -> YYObj

///|
priv enum YYDecision {
  Accept
  Shift(YYState)
  Reduce(Int, YYSymbol, YYAction)
  ReduceNoLookahead(Int, YYSymbol, YYAction)
  Error
}

///|
priv enum YYSymbol {
  T_IDENT
  T_VAR_TEMPLATE
  T_ATTRIBUTE
  T_FN
  T_STRUCT
  T_ALIAS
  T_CONST
  T_OVERRIDE
  T_LET
  T_VAR
  T_CONST_ASSERT
  T_OTHER
  NT_parse_global_header
  NT_attributes
  NT_opt_var_template
  NT_tail
  NT_tail_item
  NT_other_global
  NT_other_item
  EOI
}

// Workaround for EOI unused warning

///|
fn init {
  match (EOI : YYSymbol) {
    EOI => ()
    _ => ()
  }
}

// file:///./parser.mbty
// 30|    attributes "fn" IDENT tail
// 31|                                 { GlobalParseHeader::Function($3) }

///|
fn yy_action_0(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[2].0 is YYObj_String(_dollar3)
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Function(_dollar3)
    },
  )
}

// file:///./parser.mbty
// 32|    attributes "struct" IDENT tail
// 33|                                 { GlobalParseHeader::Struct($3) }

///|
fn yy_action_1(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[2].0 is YYObj_String(_dollar3)
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Struct(_dollar3)
    },
  )
}

// file:///./parser.mbty
// 34|    attributes "alias" IDENT tail
// 35|                                 { GlobalParseHeader::Alias($3) }

///|
fn yy_action_2(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[2].0 is YYObj_String(_dollar3)
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Alias(_dollar3)
    },
  )
}

// file:///./parser.mbty
// 36|    attributes "const" IDENT tail
// 37|                                 { GlobalParseHeader::Const($3) }

///|
fn yy_action_3(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[2].0 is YYObj_String(_dollar3)
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Const(_dollar3)
    },
  )
}

// file:///./parser.mbty
// 38|    attributes "override" IDENT tail
// 39|                                 { GlobalParseHeader::Override($3) }

///|
fn yy_action_4(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[2].0 is YYObj_String(_dollar3)
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Override(_dollar3)
    },
  )
}

// file:///./parser.mbty
// 40|    attributes "let" IDENT tail
// 41|                                 { GlobalParseHeader::Let($3) }

///|
fn yy_action_5(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[2].0 is YYObj_String(_dollar3)
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Let(_dollar3)
    },
  )
}

// file:///./parser.mbty
// 42|    attributes "var" opt_var_template IDENT tail
// 43|                                 { GlobalParseHeader::Var(GlobalParseVar::{ name: Some($4), template_arguments: $3 }) }

///|
fn yy_action_6(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[3].0 is YYObj_String(_dollar4)
  guard _args[2].0 is YYObj_String_(_dollar3)
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Var(GlobalParseVar::{
        name: Some(_dollar4),
        template_arguments: _dollar3,
      })
    },
  )
}

// file:///./parser.mbty
// 56|    VAR_TEMPLATE                  { Some($1) }

///|
fn yy_action_7(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_String(_dollar1)
  YYObj_String_(
    {
      ()
      Some(_dollar1)
    },
  )
}

// file:///./parser.mbty
// 55|                                 { None }

///|
fn yy_action_8(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_String_(
    {
      ()
      None
    },
  )
}

// file:///./parser.mbty
// 44|    attributes "const_assert" tail
// 45|                                 { GlobalParseHeader::ConstAssert }

///|
fn yy_action_9(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::ConstAssert
    },
  )
}

// file:///./parser.mbty
// 46|    attributes other_global       { GlobalParseHeader::Other }

///|
fn yy_action_10(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_GlobalParseHeader(
    {
      ()
      GlobalParseHeader::Other
    },
  )
}

// file:///./parser.mbty
// 51|    attributes ATTRIBUTE          { () }

///|
fn yy_action_11(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 61|    tail tail_item                { () }

///|
fn yy_action_12(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 65|    IDENT                         { () }

///|
fn yy_action_13(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 66|    VAR_TEMPLATE                  { () }

///|
fn yy_action_14(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 67|    ATTRIBUTE                     { () }

///|
fn yy_action_15(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 68|    "fn"                          { () }

///|
fn yy_action_16(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 69|    "struct"                      { () }

///|
fn yy_action_17(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 70|    "alias"                       { () }

///|
fn yy_action_18(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 71|    "const"                       { () }

///|
fn yy_action_19(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 72|    "override"                    { () }

///|
fn yy_action_20(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 73|    "let"                         { () }

///|
fn yy_action_21(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 74|    "var"                         { () }

///|
fn yy_action_22(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 75|    "const_assert"                { () }

///|
fn yy_action_23(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 76|    OTHER                         { () }

///|
fn yy_action_24(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 80|    other_item tail               { () }

///|
fn yy_action_25(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 60|                                 { () }

///|
fn yy_action_26(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 84|    IDENT                         { () }

///|
fn yy_action_27(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 85|    VAR_TEMPLATE                  { () }

///|
fn yy_action_28(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 86|    OTHER                         { () }

///|
fn yy_action_29(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

// file:///./parser.mbty
// 50|                                 { () }

///|
fn yy_action_30(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Unit(
    {
      ()
      ()
    },
  )
}

///|
fn yy_input(
  token : Token,
  _start_pos : Int,
  _end_pos : Int,
) -> (YYSymbol, YYObj) {
  match token {
    IDENT(data) => (T_IDENT, YYObj_String(data))
    VAR_TEMPLATE(data) => (T_VAR_TEMPLATE, YYObj_String(data))
    ATTRIBUTE => (T_ATTRIBUTE, YYObj_Void)
    FN => (T_FN, YYObj_Void)
    STRUCT => (T_STRUCT, YYObj_Void)
    ALIAS => (T_ALIAS, YYObj_Void)
    CONST => (T_CONST, YYObj_Void)
    OVERRIDE => (T_OVERRIDE, YYObj_Void)
    LET => (T_LET, YYObj_Void)
    VAR => (T_VAR, YYObj_Void)
    CONST_ASSERT => (T_CONST_ASSERT, YYObj_Void)
    OTHER => (T_OTHER, YYObj_Void)
  }
}

// [0, parse_global_header → • attributes FN IDENT tail, $]
// [1, parse_global_header → • attributes STRUCT IDENT tail, $]
// [2, parse_global_header → • attributes ALIAS IDENT tail, $]
// [3, parse_global_header → • attributes CONST IDENT tail, $]
// [4, parse_global_header → • attributes OVERRIDE IDENT tail, $]
// [5, parse_global_header → • attributes LET IDENT tail, $]
// [6, parse_global_header → • attributes VAR opt_var_template IDENT tail, $]
// [7, parse_global_header → • attributes CONST_ASSERT tail, $]
// [8, parse_global_header → • attributes other_global, $]
// [9, attributes → •, IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [10, attributes → • attributes ATTRIBUTE, IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [31, parse_global_header_prime → • parse_global_header, $]

///|
fn yy_state_0(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_parse_global_header => Shift(yy_state_1)
    NT_attributes => Shift(yy_state_2)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER => Reduce(0, NT_attributes, yy_action_30)
    _ => Error
  }
}

// [31, parse_global_header_prime → parse_global_header •, $]

///|
fn yy_state_1(_lookahead : YYSymbol) -> YYDecision {
  Accept
}

// [0, parse_global_header → attributes • FN IDENT tail, $]
// [1, parse_global_header → attributes • STRUCT IDENT tail, $]
// [2, parse_global_header → attributes • ALIAS IDENT tail, $]
// [3, parse_global_header → attributes • CONST IDENT tail, $]
// [4, parse_global_header → attributes • OVERRIDE IDENT tail, $]
// [5, parse_global_header → attributes • LET IDENT tail, $]
// [6, parse_global_header → attributes • VAR opt_var_template IDENT tail, $]
// [7, parse_global_header → attributes • CONST_ASSERT tail, $]
// [8, parse_global_header → attributes • other_global, $]
// [10, attributes → attributes • ATTRIBUTE, IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [27, other_global → • other_item tail, $]
// [28, other_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [29, other_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [30, other_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_2(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_3)
    T_VAR_TEMPLATE => Shift(yy_state_4)
    T_IDENT => Shift(yy_state_5)
    NT_other_item => Shift(yy_state_6)
    T_ATTRIBUTE => Shift(yy_state_21)
    NT_other_global => Shift(yy_state_22)
    T_CONST_ASSERT => Shift(yy_state_23)
    T_VAR => Shift(yy_state_25)
    T_LET => Shift(yy_state_30)
    T_OVERRIDE => Shift(yy_state_33)
    T_CONST => Shift(yy_state_36)
    T_ALIAS => Shift(yy_state_39)
    T_STRUCT => Shift(yy_state_42)
    T_FN => Shift(yy_state_45)
    _ => Error
  }
}

// [30, other_item → OTHER •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_3(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_other_item, yy_action_29)
}

// [29, other_item → VAR_TEMPLATE •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_4(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_other_item, yy_action_28)
}

// [28, other_item → IDENT •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_5(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_other_item, yy_action_27)
}

// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [27, other_global → other_item • tail, $]

///|
fn yy_state_6(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_7)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [27, other_global → other_item tail •, $]

///|
fn yy_state_7(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(2, NT_other_global, yy_action_25)
    _ => Error
  }
}

// [26, tail_item → OTHER •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_8(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_24)
}

// [25, tail_item → CONST_ASSERT •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_9(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_23)
}

// [24, tail_item → VAR •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_10(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_22)
}

// [23, tail_item → LET •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_11(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_21)
}

// [22, tail_item → OVERRIDE •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_12(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_20)
}

// [21, tail_item → CONST •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_13(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_19)
}

// [20, tail_item → ALIAS •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_14(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_18)
}

// [19, tail_item → STRUCT •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_15(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_17)
}

// [18, tail_item → FN •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_16(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_16)
}

// [17, tail_item → ATTRIBUTE •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_17(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_15)
}

// [16, tail_item → VAR_TEMPLATE •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_18(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_14)
}

// [15, tail_item → IDENT •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_19(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_tail_item, yy_action_13)
}

// [14, tail → tail tail_item •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_20(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_tail, yy_action_12)
}

// [10, attributes → attributes ATTRIBUTE •, IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_21(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_attributes, yy_action_11)
}

// [8, parse_global_header → attributes other_global •, $]

///|
fn yy_state_22(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_parse_global_header, yy_action_10)
}

// [7, parse_global_header → attributes CONST_ASSERT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_23(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_24)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [7, parse_global_header → attributes CONST_ASSERT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_24(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(3, NT_parse_global_header, yy_action_9)
    _ => Error
  }
}

// [6, parse_global_header → attributes VAR • opt_var_template IDENT tail, $]
// [11, opt_var_template → •, IDENT]
// [12, opt_var_template → • VAR_TEMPLATE, IDENT]

///|
fn yy_state_25(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_VAR_TEMPLATE => Shift(yy_state_26)
    NT_opt_var_template => Shift(yy_state_27)
    T_IDENT => Reduce(0, NT_opt_var_template, yy_action_8)
    _ => Error
  }
}

// [12, opt_var_template → VAR_TEMPLATE •, IDENT]

///|
fn yy_state_26(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_opt_var_template, yy_action_7)
}

// [6, parse_global_header → attributes VAR opt_var_template • IDENT tail, $]

///|
fn yy_state_27(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_28)
    _ => Error
  }
}

// [6, parse_global_header → attributes VAR opt_var_template IDENT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_28(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_29)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [6, parse_global_header → attributes VAR opt_var_template IDENT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_29(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(5, NT_parse_global_header, yy_action_6)
    _ => Error
  }
}

// [5, parse_global_header → attributes LET • IDENT tail, $]

///|
fn yy_state_30(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_31)
    _ => Error
  }
}

// [5, parse_global_header → attributes LET IDENT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_31(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_32)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [5, parse_global_header → attributes LET IDENT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_32(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(4, NT_parse_global_header, yy_action_5)
    _ => Error
  }
}

// [4, parse_global_header → attributes OVERRIDE • IDENT tail, $]

///|
fn yy_state_33(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_34)
    _ => Error
  }
}

// [4, parse_global_header → attributes OVERRIDE IDENT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_34(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_35)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [4, parse_global_header → attributes OVERRIDE IDENT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_35(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(4, NT_parse_global_header, yy_action_4)
    _ => Error
  }
}

// [3, parse_global_header → attributes CONST • IDENT tail, $]

///|
fn yy_state_36(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_37)
    _ => Error
  }
}

// [3, parse_global_header → attributes CONST IDENT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_37(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_38)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [3, parse_global_header → attributes CONST IDENT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_38(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(4, NT_parse_global_header, yy_action_3)
    _ => Error
  }
}

// [2, parse_global_header → attributes ALIAS • IDENT tail, $]

///|
fn yy_state_39(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_40)
    _ => Error
  }
}

// [2, parse_global_header → attributes ALIAS IDENT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_40(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_41)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [2, parse_global_header → attributes ALIAS IDENT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_41(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(4, NT_parse_global_header, yy_action_2)
    _ => Error
  }
}

// [1, parse_global_header → attributes STRUCT • IDENT tail, $]

///|
fn yy_state_42(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_43)
    _ => Error
  }
}

// [1, parse_global_header → attributes STRUCT IDENT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_43(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_44)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [1, parse_global_header → attributes STRUCT IDENT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_44(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(4, NT_parse_global_header, yy_action_1)
    _ => Error
  }
}

// [0, parse_global_header → attributes FN • IDENT tail, $]

///|
fn yy_state_45(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_46)
    _ => Error
  }
}

// [0, parse_global_header → attributes FN IDENT • tail, $]
// [13, tail → •, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [14, tail → • tail tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_46(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_tail => Shift(yy_state_47)
    T_IDENT
    | T_VAR_TEMPLATE
    | T_ATTRIBUTE
    | T_FN
    | T_STRUCT
    | T_ALIAS
    | T_CONST
    | T_OVERRIDE
    | T_LET
    | T_VAR
    | T_CONST_ASSERT
    | T_OTHER
    | EOI => Reduce(0, NT_tail, yy_action_26)
    _ => Error
  }
}

// [0, parse_global_header → attributes FN IDENT tail •, $]
// [14, tail → tail • tail_item, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [15, tail_item → • IDENT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [16, tail_item → • VAR_TEMPLATE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [17, tail_item → • ATTRIBUTE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [18, tail_item → • FN, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [19, tail_item → • STRUCT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [20, tail_item → • ALIAS, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [21, tail_item → • CONST, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [22, tail_item → • OVERRIDE, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [23, tail_item → • LET, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [24, tail_item → • VAR, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [25, tail_item → • CONST_ASSERT, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]
// [26, tail_item → • OTHER, $ / IDENT / VAR_TEMPLATE / ATTRIBUTE / FN / STRUCT / ALIAS / CONST / OVERRIDE / LET / VAR / CONST_ASSERT / OTHER]

///|
fn yy_state_47(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_OTHER => Shift(yy_state_8)
    T_CONST_ASSERT => Shift(yy_state_9)
    T_VAR => Shift(yy_state_10)
    T_LET => Shift(yy_state_11)
    T_OVERRIDE => Shift(yy_state_12)
    T_CONST => Shift(yy_state_13)
    T_ALIAS => Shift(yy_state_14)
    T_STRUCT => Shift(yy_state_15)
    T_FN => Shift(yy_state_16)
    T_ATTRIBUTE => Shift(yy_state_17)
    T_VAR_TEMPLATE => Shift(yy_state_18)
    T_IDENT => Shift(yy_state_19)
    NT_tail_item => Shift(yy_state_20)
    EOI => Reduce(4, NT_parse_global_header, yy_action_0)
    _ => Error
  }
}

///|
fn[T] yy_parse(
  tokens : Array[(Token, Int, Int)],
  start : YYState,
  return_ : (YYObj) -> T,
  initial_pos? : Int,
) -> T raise ParseError {
  let mut cursor = 0
  let mut state_stack : @list.List[YYState] = @list.cons(start, @list.empty())
  let data_stack : Array[(YYObj, Int, Int)] = []
  let mut last_pos = initial_pos.unwrap_or(tokens[0].1)
  let mut state = start
  let mut lookahead : (YYSymbol, (YYObj, Int, Int), Token?)? = None
  let mut last_shifted_state_stack = state_stack
  while true {
    let decision = match state(EOI) {
      ReduceNoLookahead(_) | Accept as t => t
      _ =>
        match lookahead {
          Some(la) => state(la.0)
          None =>
            if cursor < tokens.length() {
              let (token, start_pos, end_pos) = tokens[cursor]
              cursor += 1
              let (symbol, data) = yy_input(token, start_pos, end_pos)
              lookahead = Some(
                (symbol, (data, start_pos, end_pos), Some(token)),
              )
              state(symbol)
            } else {
              lookahead = Some((EOI, (YYObj_Void, last_pos, last_pos), None))
              state(EOI)
            }
        }
    }
    match decision {
      Accept => return return_(data_stack.unsafe_pop().0)
      Shift(next_state) => {
        guard lookahead is Some(la)
        data_stack.push(la.1)
        state_stack = @list.cons(next_state, state_stack)
        last_shifted_state_stack = state_stack
        state = next_state
        last_pos = la.1.2
        lookahead = None
      }
      Reduce(count, symbol, action)
      | ReduceNoLookahead(count, symbol, action) =>
        for count = count, symbol = symbol, action = action {
          let args = data_stack[data_stack.length() - count:]
          let data = action(last_pos, args)
          let (start_pos, end_pos) = if args.length() == 0 {
            (last_pos, last_pos)
          } else {
            (args[0].1, args[args.length() - 1].2)
          }
          for _ in 0..<count {
            ignore(data_stack.unsafe_pop())
            state_stack = state_stack.unsafe_tail()
          }
          state = state_stack.unsafe_head()
          data_stack.push((data, start_pos, end_pos))
          match state(symbol) {
            Accept => return return_(data_stack.unsafe_pop().0)
            Shift(next_state) => {
              state_stack = @list.cons(next_state, state_stack)
              state = next_state
              break ()
            }
            Reduce(count, symbol, action)
            | ReduceNoLookahead(count, symbol, action) =>
              continue count, symbol, action
            _ => panic()
          }
        }
      Error => {
        let (_, (_, start_pos, end_pos), token) = lookahead.unwrap()
        error(last_shifted_state_stack, token, (start_pos, end_pos))
      }
    }
  }
  panic()
}

///|
fn error(
  stack : @list.List[YYState],
  token : Token?,
  loc : (Int, Int),
) -> Unit raise ParseError {
  let expected = []
  fn try_add(symbol : YYSymbol, kind : TokenKind) {
    fn go(stack : @list.List[YYState]) {
      match stack {
        Empty => ()
        More(state, ..) =>
          match state(symbol) {
            Accept | Shift(_) => expected.push(kind)
            Reduce(count, symbol, _) | ReduceNoLookahead(count, symbol, _) => {
              fn inner_go(stack : @list.List[YYState], count, symbol) {
                let stack = stack.drop(count)
                guard stack is More(state, ..)
                match state(symbol) {
                  Shift(state) => go(@list.cons(state, stack))
                  Reduce(count, symbol, _)
                  | ReduceNoLookahead(count, symbol, _) =>
                    inner_go(stack, count, symbol)
                  _ => panic()
                }
              }
              inner_go(stack, count, symbol)
            }
            Error => ()
          }
      }
    }
    go(stack)
  }
  for
    term in (
      [
        (T_IDENT, TK_IDENT),
        (T_VAR_TEMPLATE, TK_VAR_TEMPLATE),
        (T_ATTRIBUTE, TK_ATTRIBUTE),
        (T_FN, TK_FN),
        (T_STRUCT, TK_STRUCT),
        (T_ALIAS, TK_ALIAS),
        (T_CONST, TK_CONST),
        (T_OVERRIDE, TK_OVERRIDE),
        (T_LET, TK_LET),
        (T_VAR, TK_VAR),
        (T_CONST_ASSERT, TK_CONST_ASSERT),
        (T_OTHER, TK_OTHER),
      ] : Array[(YYSymbol, TokenKind)]) {
    try_add(term.0, term.1)
  }
  match token {
    None => raise UnexpectedEndOfInput(loc.1, expected)
    Some(token) => raise UnexpectedToken(token, loc, expected)
  }
}

///|
pub fn parse_global_header(
  tokens : Array[(Token, Int, Int)],
  initial_pos? : Int,
) -> GlobalParseHeader raise ParseError {
  yy_parse(
    tokens,
    yy_state_0,
    it => {
      guard it is YYObj_GlobalParseHeader(result)
      result
    },
    initial_pos?,
  )
}
