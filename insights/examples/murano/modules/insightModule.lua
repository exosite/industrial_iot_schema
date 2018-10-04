insightModule = {}

function insightModule.addNumbers(body)
  local dataIN = body.data
  local constants = body.args.constants
  dataOUT = {}

-- dataIN is a list of datapoints
  for _, dp in pairs(dataIN) do

    -- Each signal value in dataOUT should keep the incoming metadata
    dp.value = dp.value + constants.adder

    table.insert(dataOUT, dp)
  end
  return dataOUT
end
