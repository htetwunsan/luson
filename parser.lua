---@class Parser
---@field private source string
---@field private current number
Parser = {}

---@param o {source: string}
---@return Parser
function Parser:new(o)
    local p = {
        source = o.source,
        current = 1
    }
    setmetatable(p, self)
    self.__index = self
    return p
end

function Parser:parse()
    return self:jsonValue()
end

---@private
function Parser:isAtEnd()
    return self.current > #self.source
end

---@private
function Parser:advance()
    local ch = self.source:sub(self.current, self.current)
    self.current = self.current + 1
    return ch
end

---@private
function Parser:lookahead()
    return self.source:sub(self.current, self.current)
end

---@private
---@param expected string
function Parser:match(expected)
    assert(#expected == 1)

    if (self:lookahead() ~= expected) then return false end

    self:advance()
    return true
end

---@private
---@param expected string
function Parser:char(expected)
    assert(#expected == 1)

    local ch = self:advance()

    if expected ~= ch then
        error(("expected '%s', received '%s'"):format(expected, ch))
    end

    return expected
end

---@private
---@param expected string
function Parser:string(expected)
    for i = 1, #expected do
        self:char(expected:sub(i, i))
    end

    return expected
end

---@private
function Parser:jsonValue()
    local ch = self:lookahead()
    if ch == 'n' then
        return self:jsonNull()
    elseif ch == 't' then
        return self:jsonTrue()
    elseif ch == 'f' then
        return self:jsonFalse()
    elseif ch == '-' or ch:match("%d") then
        return self:jsonNumber()
    elseif ch == '"' then
        return self:jsonString()
    elseif ch == '[' then
        return self:jsonArray()
    elseif ch == '{' then
        return self:jsonObject()
    else
        error(("expected 'n|t|f|-|digit|\"|[|{', recevied '%s'"):format(ch))
    end
end

---@private
function Parser:jsonNull()
    self:string("null")

    return nil
end

---@private
function Parser:jsonTrue()
    self:string("true")

    return true
end

---@private
function Parser:jsonFalse()
    self:string("false")

    return false
end

---@private
function Parser:jsonNumber()
    local start = self.current
    -- integer
    if self:match('-') and not self:lookahead():match("%d") then
        error(("expected 'digit', received '%s'"):format(self:lookahead()))
    end

    if self:match('0') and self:lookahead():match("%d") then
        error(("unexpected number %s"):format("0" .. self:lookahead()))
    end

    while self:lookahead():match("%d") do
        self:advance()
    end

    -- fraction
    if self:match('.') then
        while self:lookahead():match("%d") do
            self:advance()
        end
    end

    -- exponent
    if self:match('e') or self:match('E') then
        if (self:match('-') or self:match('+')) and not self:lookahead():match("%d") then
            error(("expected 'digit', received '%s'").format(self:lookahead()))
        end

        while self:lookahead():match("%d") do
            self:advance()
        end
    end

    return tonumber(self.source:sub(start, self.current - 1))
end

---@private
function Parser:jsonString()
    local buffer = {""}
    if not self:match('"') then
        error(("expected '\"', received '%s'"):format(self:lookahead()))
    end

    while not self:match('"') do
        if self:match('\\') then
            if self:match('"') then
                table.insert(buffer, '\"')
            elseif self:match('\\') then
                table.insert(buffer, '\\\\')
            elseif self:match('/') then
                table.insert(buffer, '/')
            elseif self:match('b') then
                table.insert(buffer, '\\b')
            elseif self:match('f') then
                table.insert(buffer, '\\f')
            elseif self:match('n') then
                table.insert(buffer, '\\n')
            elseif self:match('r') then
                table.insert(buffer, '\\r')
            elseif self:match('t') then
                table.insert(buffer, '\\t')
            else
                error(("expected 'escaped characters', received '%s'"):format(self:lookahead()))
            end
        else
            table.insert(buffer, self:advance())
        end
    end

    return table.concat(buffer)
end

---@private
function Parser:jsonArray()
    if not self:match('[') then
        error(("expected '[', recevied '%s'"):format(self:lookahead()))
    end

    while self:lookahead():match("%s") do
        self:advance()
    end

    local array = {}

    while not self:match(']') do
        while self:lookahead():match("%s") do
            self:advance()
        end

        table.insert(array, self:jsonValue())

        while self:lookahead():match("%s") do
            self:advance()
        end

        self:match(',')
    end

    return array
end

---@private
function Parser:jsonObject()
    if not self:match('{') then
        error(("expected '{', received '%s'"):format(self:lookahead()))
    end

    while self:lookahead():match("%s") do
        self:advance()
    end

    local object = {}

    while not self:match('}') do
        while self:lookahead():match("%s") do
            self:advance()
        end

        local key = self:jsonString()

        while self:lookahead():match("%s") do
            self:advance()
        end

        if not self:match(':') then
            error(("expected ':', received '%s'"):format(self:lookahead()))
        end

        while self:lookahead():match("%s") do
            self:advance()
        end

        local val = self:jsonValue()

        while self:lookahead():match("%s") do
            self:advance()
        end

        object[key] = val

        self:match(',')
    end

    return object
end

---@param source string
local function parse(source)
    local parser = Parser:new{source = source}

    return parser:parse()
end

return {
    parse = parse
}
