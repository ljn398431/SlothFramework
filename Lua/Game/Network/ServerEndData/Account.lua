local M = {}
local account = {
	characterCode = "",
	name = "",
	gender = "1",
	token = "",
	bgUrl = "",
	alpha = 0.5,
	areaCode = "",
	areas = {},
}

function M.Init()
	print("init account")
	account.characterCode = ""
end

function M.GetData()
	return account
end

function M.ParseFromServerData(serverData)
	account.userId = serverData["accountUuid"]
	table.assign(account, serverData)
end

return M