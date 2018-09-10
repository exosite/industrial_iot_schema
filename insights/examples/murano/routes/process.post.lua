--#ENDPOINT POST /process
-- process

local args = request.body.args
local functionId = args.function_id
local groupId = args.group_id
local constants = args.constants

local dataOUT = insightModule[functionId](request.body)

return {dataOUT}
