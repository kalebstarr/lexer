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

fn tokenize(allocator: std.mem.Allocator, buffer: []const u8, delimiters: []const u8) !TokenIterator {
    var token_map = std.StringHashMap(TokenType).init(allocator);
    try token_map.put("if", TokenType{ .keyword = Keyword.control_flow });
    try token_map.put("else", TokenType{ .keyword = Keyword.control_flow });
    try token_map.put("while", TokenType{ .keyword = Keyword.control_flow });
    try token_map.put("for", TokenType{ .keyword = Keyword.control_flow });
    try token_map.put("switch", TokenType{ .keyword = Keyword.control_flow });
    try token_map.put("break", TokenType{ .keyword = Keyword.control_flow });
    try token_map.put("continue", TokenType{ .keyword = Keyword.control_flow });
    try token_map.put("return", TokenType{ .keyword = Keyword.control_flow });

    try token_map.put("int", TokenType{ .keyword = Keyword.type_decl });
    try token_map.put("string", TokenType{ .keyword = Keyword.type_decl });
    try token_map.put("bool", TokenType{ .keyword = Keyword.type_decl });
    try token_map.put("void", TokenType{ .keyword = Keyword.type_decl });
    try token_map.put("class", TokenType{ .keyword = Keyword.type_decl });
    try token_map.put("struct", TokenType{ .keyword = Keyword.type_decl });

    try token_map.put("public", TokenType{ .keyword = Keyword.modifier });
    try token_map.put("private", TokenType{ .keyword = Keyword.modifier });
    try token_map.put("static", TokenType{ .keyword = Keyword.modifier });
    try token_map.put("const", TokenType{ .keyword = Keyword.modifier });

    try token_map.put("true", TokenType{ .keyword = Keyword.logic });
    try token_map.put("false", TokenType{ .keyword = Keyword.logic });
    try token_map.put("null", TokenType{ .keyword = Keyword.logic });

    try token_map.put("+", TokenType{ .operator = Operator.arithmetic });
    try token_map.put("-", TokenType{ .operator = Operator.arithmetic });
    try token_map.put("*", TokenType{ .operator = Operator.arithmetic });
    try token_map.put("/", TokenType{ .operator = Operator.arithmetic });
    try token_map.put("%", TokenType{ .operator = Operator.arithmetic });
    try token_map.put("**", TokenType{ .operator = Operator.arithmetic });

    try token_map.put("==", TokenType{ .operator = Operator.comparison });
    try token_map.put("!=", TokenType{ .operator = Operator.comparison });
    try token_map.put("<", TokenType{ .operator = Operator.comparison });
    try token_map.put(">", TokenType{ .operator = Operator.comparison });
    try token_map.put("<=", TokenType{ .operator = Operator.comparison });
    try token_map.put(">=", TokenType{ .operator = Operator.comparison });
    try token_map.put("===", TokenType{ .operator = Operator.comparison });
    try token_map.put("!==", TokenType{ .operator = Operator.comparison });

    try token_map.put("&&", TokenType{ .operator = Operator.logical });
    try token_map.put("||", TokenType{ .operator = Operator.logical });
    try token_map.put("!", TokenType{ .operator = Operator.logical });

    try token_map.put("&", TokenType{ .operator = Operator.bitwise });
    try token_map.put("|", TokenType{ .operator = Operator.bitwise });
    try token_map.put("^", TokenType{ .operator = Operator.bitwise });
    try token_map.put("~", TokenType{ .operator = Operator.bitwise });
    try token_map.put("<<", TokenType{ .operator = Operator.bitwise });
    try token_map.put(">>", TokenType{ .operator = Operator.bitwise });

    try token_map.put("=", TokenType{ .operator = Operator.assignment });
    try token_map.put("+=", TokenType{ .operator = Operator.assignment });
    try token_map.put("-=", TokenType{ .operator = Operator.assignment });
    try token_map.put("*=", TokenType{ .operator = Operator.assignment });
    try token_map.put("/=", TokenType{ .operator = Operator.assignment });
    try token_map.put("%=", TokenType{ .operator = Operator.assignment });
    try token_map.put("&=", TokenType{ .operator = Operator.assignment });
    try token_map.put("|=", TokenType{ .operator = Operator.assignment });
    try token_map.put("^=", TokenType{ .operator = Operator.assignment });
    try token_map.put("<<=", TokenType{ .operator = Operator.assignment });
    try token_map.put(">>=", TokenType{ .operator = Operator.assignment });

    // TODO: Add unary operators
    // TODO: Add ternary operators

    try token_map.put("(", TokenType{ .delimiter = Delimiter.bracket });
    try token_map.put(")", TokenType{ .delimiter = Delimiter.bracket });
    try token_map.put("[", TokenType{ .delimiter = Delimiter.bracket });
    try token_map.put("]", TokenType{ .delimiter = Delimiter.bracket });
    try token_map.put("{", TokenType{ .delimiter = Delimiter.bracket });
    try token_map.put("}", TokenType{ .delimiter = Delimiter.bracket });

    // TODO: Add separator delimiters
    // TODO: Add arrow delimiters

    return .{
        .index = 0,
        .buffer = buffer,
        .delimiter = delimiters,
        .token_map = token_map,
    };
}

const TokenIterator = struct {
    buffer: []const u8,
    delimiter: []const u8,
    index: usize,
    token_map: std.StringHashMap(TokenType),

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.token_map.deinit();
    }

    pub fn next(self: *Self) ?[]const u8 {
        const result = self.peek() orelse return null;
        self.index += result.len;
        return result;
    }

    pub fn peek(self: *Self) ?[]const u8 {
        if (self.index >= self.buffer.len) {
            return null;
        }

        const start = self.index;

        if (self.isDelimiter(start)) {
            return self.buffer[start..(start + 1)];
        } else {
            var end = start;
            while (end < self.buffer.len and !self.isDelimiter(end)) : (end += 1) {}
            return self.buffer[start..end];
        }
    }

    pub fn rest(self: Self) []const u8 {
        var index: usize = self.index;
        while (index < self.buffer.len and self.isDelimiter(index)) : (index += 1) {}
        return self.buffer[index..];
    }

    pub fn reset(self: *Self) void {
        self.index = 0;
    }

    fn isDelimiter(self: Self, index: usize) bool {
        const item = self.buffer[index];
        for (self.delimiter) |delimiter_item| {
            if (item == delimiter_item) {
                return true;
            }
        }
        return false;
    }
};

test TokenIterator {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer {
        const gpa_status = gpa.deinit();
        if (gpa_status == .leak) {
            std.testing.expect(false) catch @panic("TEST FAIL");
        }
    }
    const allocator = gpa.allocator();

    var it = try tokenize(allocator, "Jest something", " ");
    defer it.deinit();

    try std.testing.expectEqualStrings("Jest", it.next().?);
    try std.testing.expectEqualStrings(" ", it.next().?);
    try std.testing.expectEqualStrings("something", it.next().?);
}
