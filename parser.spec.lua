local describe = require("spec")
local parser = require("parser")


describe("jsonNull", function (it)
    it("can parse null", function ()
        assert(parser.parse("null") == nil)
    end)
end)

describe("jsonBool", function (it)
    it("can parse true", function ()
        assert(parser.parse("true") == true)
    end)

    it("can parse false", function ()
        assert(parser.parse("false") == false)
    end)
end)

describe("jsonNumber", function (it)
    it("can parse integer", function ()
        assert(pcall(parser.parse, "-a") == false)
        assert(pcall(parser.parse, "01") == false)

        assert(parser.parse("-0") == 0)
        assert(parser.parse("100") == 100)
    end)

    it("can parse integer fraction", function ()
        assert(pcall(parser.parse, "-a.10") == false)
        assert(pcall(parser.parse, "01.10") == false)

        assert(parser.parse("-0.10") == -0.10)
        assert(parser.parse("100.10") == 100.10)
    end)

    it("can parse integer exponent", function ()
        assert(pcall(parser.parse, "-ae10") == false)
        assert(pcall(parser.parse, "01e10") == false)

        assert(parser.parse("-0e10") == 0)

        assert(parser.parse("100e10") == 1000000000000)
        assert(parser.parse("100E10") == 1000000000000)

        assert(parser.parse("100e+10") == 1000000000000)
        assert(parser.parse("100E+10") == 1000000000000)

        assert(parser.parse("100e-10") == 0.00000001)
        assert(parser.parse("100E-10") == 0.00000001)
    end)

    it("can parse integer fraction exponent", function ()
        assert(pcall(parser.parse, "-a.10.e10") == false)
        assert(pcall(parser.parse, "01.10e10") == false)

        assert(parser.parse("-0.10e10") == -1000000000.0)

        assert(parser.parse("100.10e10") == 1001000000000.0)
        assert(parser.parse("100.10E10") == 1001000000000.0)

        assert(parser.parse("100.10e+10") == 1001000000000.0)
        assert(parser.parse("100.10E+10") == 1001000000000.0)

        assert(parser.parse("100.10e-10") == 0.00000001001)
        assert(parser.parse("100.10E-10") == 0.00000001001)
    end)
end)

describe("jsonString", function (it)
    it("can parse string", function ()
        assert(parser.parse("\"Hello World\"") == "Hello World")
    end)

    it("can parse escaped string", function ()
        assert(parser.parse("\"\\\"\"") == '\"')
        assert(parser.parse("\"\\\\\"") == '\\\\')
        assert(parser.parse("\"\\/\"") == '/')
        assert(parser.parse("\"\\b\"") == '\\b')
        assert(parser.parse("\"\\f\"") == '\\f')
        assert(parser.parse("\"\\n\"") == '\\n')
        assert(parser.parse("\"\\r\"") == '\\r')
        assert(parser.parse("\"\\t\"") == '\\t')
    end)
    it("can parse unicode string", function ()
        assert(false)
    end)
end)

describe("jsonArray", function (it)
    it("can parse empty array", function ()
        local array = parser.parse("[  ]")

        assert(type(array) == "table")
        assert(#array == 0)
    end)

    it("can parse null array", function ()
        local array = parser.parse("[null, null ]")

        assert(type(array) == "table")
        assert(#array == 0)
    end)

    it("can parse array", function ()
        local array = parser.parse("[  \"Hello\"  , 1.01 , null, true   , false, [ null, \"World\" ] ]")

        assert(type(array) == "table")
        assert(#array == 5)
        assert(array[1] == "Hello")
        assert(array[2] == 1.01)
        assert(array[3] == true)
        assert(array[4] == false)
        assert(#array[5] == 1)
        assert(array[5][1] == "World")
    end)
end)

describe("jsonObject", function (it)
    it("can parse empty object", function ()
        local object = parser.parse("{  }")

        assert(type(object) == "table")
        assert(#object == 0)
    end)

    it("can parse object", function ()
        local object = parser.parse("{\n\t\f\r\n \"Hello\" :\n\t\"World\"  }")

        assert(type(object) == "table")
        assert(object.Hello == "World")
    end)
end)

describe("test.json", function (it)
    it("can parse json file", function ()
        local fd = assert(io.open("test.json", "r"))
        local bytes = fd:read("a")
        local object = parser.parse(bytes)

        assert(type(object) == "table")

        local glossary = object.glossary
        assert(glossary.title == "example glossary")

        local glossDiv = glossary.GlossDiv
        assert(glossDiv.title == "S")

        local glossEntry = glossDiv.GlossList.GlossEntry
        assert(glossEntry.ID == "SGML")
        assert(glossEntry.SortAs == "SGML")
        assert(glossEntry.GlossTerm == "Standard Generalized Markup Language")
        assert(glossEntry.Acronym == "SGML")
        assert(glossEntry.Abbrev == "ISO 8879:1986")
        local glossDef = glossEntry.GlossDef
        assert(glossDef.para == "A meta-markup language, used to create markup languages such as DocBook.")
        local glossSeeAlso = glossDef.GlossSeeAlso
        assert(glossSeeAlso[1] == "GML")
        assert(glossSeeAlso[2] == "XML")
        assert(glossEntry.GlossSee == "markup")
    end)
end)


