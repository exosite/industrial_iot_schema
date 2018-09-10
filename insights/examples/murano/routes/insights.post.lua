--#ENDPOINT POST /insights
-- listInsights

local insightsByGroup = {}
local emptyList = {}
setmetatable(emptyList, {['__type']='slice'})

local addNumber = {
  id = "addNumbers",
  name = "Add Numbers",
  description = "Sum one data point and a user-defined value",
  constants = {
    {
      name = "adder",
      type = "number"
    }
  },
  inlets = {
    {
      data_type = "NUMBER",
      data_unit = "",
      description = "One number"
    }
  },
  outlets = {
    data_type = "NUMBER",
    data_unit = ""
  }
}

insightsByGroup["80000001"] = {addNumber}
insightsByGroup["80000002"] = emptyList

if request.body.group_id == '' then
  insightGroup = emptyList 
else
  insightGroup = insightsByGroup[request.body.group_id]
end

local requestedGroup = insightGroup
if insightGroup == nil then
  return {error = "group_id "..request.body.group_id.." does not exist"}
end
local count = table.getn(requestedGroup)
local total = table.getn(requestedGroup)

return {
  count = count,
  total = total,
  insights = requestedGroup
}
