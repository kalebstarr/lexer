const std = @import("std");

pub const Token = struct {
    token_type: TokenType,
    token_str: []const u8,
};

pub const TokenType = union(enum) {
    keyword: Keyword,
    identifier,
    literal: Literal,
    operator: Operator,
    delimiter: Delimiter,
    unknown,
};

pub const Keyword = enum {
    control_flow,
    type_decl,
    modifier,
    logic,
};

pub const Literal = enum {
    integer,
    float,
    string,
    character,
    boolean,
    none,
};

pub const Operator = enum {
    arithmetic,
    comparison,
    logical,
    bitwise,
    assignment,
    unary,
    ternary,
    other,
};

pub const Delimiter = enum {
    bracket,
    separator,
    arrow,
    whitespace,
    newline,
    eof,
    indent,
};

pub fn genericTokenize(allocator: std.mem.Allocator, buffer: []const u8, delimiters: []const u8) !TokenIterator {
    const token_map = try initGenericTokenMap(allocator);

    var delimiter_list = std.ArrayList(u8).empty;
    try delimiter_list.appendSlice(allocator, delimiters);
    var it = token_map.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* == .delimiter) {
            try delimiter_list.appendSlice(allocator, entry.key_ptr.*);
        }
    }

    return .{
        .allocator = allocator,
        .index = 0,
        .buffer = buffer,
        .delimiter = delimiter_list,
        .token_map = token_map,
    };
}

pub fn initGenericTokenMap(allocator: std.mem.Allocator) !std.StringHashMap(TokenType) {
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

    try token_map.put(" ", TokenType{ .delimiter = Delimiter.whitespace });
    try token_map.put(".", TokenType{ .delimiter = Delimiter.separator });
    try token_map.put("\n", TokenType{ .delimiter = Delimiter.newline });
    try token_map.put("\r\n", TokenType{ .delimiter = Delimiter.newline });

    return token_map;
}

pub const TokenIterator = struct {
    allocator: std.mem.Allocator,
    buffer: []const u8,
    delimiter: std.ArrayList(u8),
    index: usize,
    token_map: std.StringHashMap(TokenType),

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.delimiter.deinit(self.allocator);
        self.token_map.deinit();
    }

    pub fn next(self: *Self) ?Token {
        const result = self.peek() orelse return null;
        self.index += result.token_str.len;
        return result;
    }

    pub fn peek(self: *Self) ?Token {
        if (self.index >= self.buffer.len) {
            return null;
        }

        const start = self.index;
        var end = start;

        var is_delimiter = false;
        if (self.isDelimiter(start)) {
            end += 1;
            is_delimiter = true;
        } else {
            while (end < self.buffer.len and !self.isDelimiter(end)) : (end += 1) {}
        }

        const slice = self.buffer[start..end];
        const opt_token_type = self.token_map.get(slice);
        const token_type: TokenType = opt_token_type orelse
            (if (is_delimiter) .unknown else .identifier);
        return .{
            .token_type = token_type,
            .token_str = slice,
        };
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
        for (self.delimiter.items) |delimiter_item| {
            if (item == delimiter_item) {
                return true;
            }
        }
        return false;
    }
};

test "TokenIterator with generic token_map" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer {
        const gpa_status = gpa.deinit();
        if (gpa_status == .leak) {
            std.testing.expect(false) catch @panic("TEST FAIL");
        }
    }
    const allocator = gpa.allocator();

    var it = try genericTokenize(allocator, "Jest something if.", " ");
    defer it.deinit();

    var result = it.next();
    try std.testing.expectEqualDeep(Token{ .token_type = .identifier, .token_str = "Jest" }, result.?);
    result = it.next();
    try std.testing.expectEqualDeep(Token{ .token_type = .{ .delimiter = .whitespace }, .token_str = " " }, result.?);
    result = it.next();
    try std.testing.expectEqualDeep(Token{ .token_type = .identifier, .token_str = "something" }, result.?);
    result = it.next();
    try std.testing.expectEqualDeep(Token{ .token_type = .{ .delimiter = .whitespace }, .token_str = " " }, result.?);
    result = it.next();
    try std.testing.expectEqualDeep(Token{ .token_type = .{ .keyword = .control_flow }, .token_str = "if" }, result.?);
    result = it.next();
    try std.testing.expectEqualDeep(Token{ .token_type = .{ .delimiter = .separator }, .token_str = "." }, result.?);
}
