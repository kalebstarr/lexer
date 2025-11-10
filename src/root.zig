const std = @import("std");

const Token = struct {
    token_type: TokenType,
};

const TokenType = union(enum) {
    keyword: Keyword,
    identifier,
    literal: Literal,
    operator: Operator,
    delimiter: Delimiter,
    special: Special,
};

const Keyword = enum {
    control_flow,
    type_decl,
    modifier,
    logic,
};

const Literal = enum {
    integer,
    float,
    string,
    character,
    boolean,
    none,
};

const Operator = enum {
    arithmetic,
    comparison,
    logical,
    bitwise,
    assignment,
    unary,
    ternary,
    other,
};

const Delimiter = enum {
    bracket,
    separator,
    arrow,
};

const Special = enum {
    eof,
    newline,
    indent,
};
