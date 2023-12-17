local StringToHash = CS.UnityEngine.Animator.StringToHash
return setmetatable({}, {
	__index = function(t, k)
		t[k] = StringToHash(k)
		return t[k]
	end
})
