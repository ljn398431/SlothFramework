local Shader = CS.UnityEngine.Shader
return setmetatable({}, {
	__index = function(t, k)
		t[k] = Shader.PropertyToID(k)
		return t[k]
	end
})
