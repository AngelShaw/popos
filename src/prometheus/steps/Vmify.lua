-- This Script is Part of the Prometheus Obfuscator by levno-710
--
-- Vmify.lua
--
-- This Script provides a Complex Obfuscation Step that will compile the entire Script to a fully custom bytecode that does not share its instructions
-- with Lua, making it much harder to crack than other Lua obfuscators.
local Step = require("prometheus.step");
local Compiler = require("prometheus.compiler.compiler");

local Vmify = Step:extend();
Vmify.Description = "This Step will compile your script into a fully custom bytecode format and emit a VM for executing it.";
Vmify.Name = "Vmify";
Vmify.SettingsDescriptor = {
    -- The VM program counter is encoded with a per-build affine permutation.
    -- Set this to false only when reproducing legacy output for troubleshooting.
    StateEncoding = {
        type = "boolean",
        default = true,
        aliases = { "EncodeState" },
    },
    -- Route global reads and writes through a per-instance table proxy.
    -- This changes the VM shape while preserving ordinary Lua 5.1 semantics.
    EnvironmentProxy = {
        type = "boolean",
        default = true,
        aliases = { "ProxyEnvironment" },
    },
};

function Vmify:init(_) end

function Vmify:apply(ast)
    local compiler = Compiler:new({
        StateEncoding = self.StateEncoding,
        EnvironmentProxy = self.EnvironmentProxy,
    });
    return compiler:compile(ast);
end

return Vmify;
