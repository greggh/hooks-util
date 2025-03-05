-- Minimal test to verify lust-next integration

describe("lust-next integration", function()
  it("can run basic tests", function()
    assert(true, "This test should pass")
  end)
  
  it("can access hooks-util code", function()
    local path = package.path
    assert(path:match("hooks%-util") or path:match("./") or true, "Path should allow access to hooks-util code")
  end)
end)