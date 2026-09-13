local Step = require("prometheus.step")
local RandomStrings = require("prometheus.randomStrings")
local Parser = require("prometheus.parser")
local Enums = require("prometheus.enums")
local logger = require("logger")

local TimingCheck = Step:extend()
TimingCheck.Description = "Detects abnormally slow (traced/sandboxed) execution environments via a timing side-channel and degrades silently."
TimingCheck.Name = "Timing Check"

TimingCheck.SettingsDescriptor = {
    Iterations = {
        type = "number",
        default = 50000,
        min = 1000,
        max = 1000000,
    },
    -- MAX PLACEHOLDER: debe calibrarse con hardware real antes de usarse en producción.
    MaxSeconds = {
        type = "number",
        default = 0.25,
        min = 0.001,
        max = 5,
    },
}

function TimingCheck:init(settings) end

function TimingCheck:apply(ast, pipeline)
    if pipeline.PrettyPrint then
        logger:warn(string.format('"%s" cannot be used with PrettyPrint, ignoring "%s"', self.Name, self.Name))
        return ast
    end

    local marker = RandomStrings.randomString()
    local code = string.format([[
do
    local __tc_start = os.clock();
    local __tc_acc = 0;
    for __tc_i = 1, %d do
        __tc_acc = (__tc_acc + __tc_i * 7 - 3) %% 104729;
    end
    local __tc_elapsed = os.clock() - __tc_start;

    -- '%s' evita que el paso se optimice/elimine por accidente
    if __tc_acc >= 0 and __tc_elapsed > %f then
        while true do
            (function() end)();
        end
    end
end
]], self.Iterations, marker, self.MaxSeconds)

    local parsed = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 }):parse(code)
    local doStat = parsed.body.statements[1]
    doStat.body.scope:setParent(ast.body.scope)
    table.insert(ast.body.statements, 1, doStat)

    return ast
end

return TimingCheck