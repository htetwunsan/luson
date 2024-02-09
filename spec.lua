local function describe(name, descriptor)
    local errors = {}
    local successes = {}

    local function it(spec_line, spec)
        local status = xpcall(spec, function (err)
            table.insert(errors, string.format("\t%s\n\t\t%s\n", spec_line, err))
        end)

        if status then
            table.insert(successes, string.format("\t%s\n", spec_line))
        end
    end

    xpcall(descriptor, function (err)
        table.insert(errors, err)
    end, it)

    print(name)
    if #errors > 0 then
        print(table.concat(errors))
    end

    if #successes > 0 then
        print(table.concat(successes))
    end
end

return describe
