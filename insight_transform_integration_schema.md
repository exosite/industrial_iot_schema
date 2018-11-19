# ExoSense™ Insight Transform Schema

**Document Status:** Draft

## Processing Signal Data

### Getting Signal History

The Insight Function Info schema accepts a `history` parameter, which attaches
historical data from inlet Signals to the outgoing `POST /process` request. The
`history` block supports many Murano TSDB query parameters and the values of
those parameters can be injected in several ways by the Pipeline. First, an
example.

#### Example

Your function defines the following `constants` and `history` blocks:

```json
{
  "constants": [
    {
      "name": "days",
      "type": "number",
      "description": "The number of previous days to analyze",
      "default": 1,
      "maximum": 7,
      "minimum": 1
    },
    {
      "name": "aggregation_function",
      "type": "string",
      "description": "The aggregation function to use",
      "enum": ["avg", "max", "min", "count", "sum"],
      "default": "avg"
    }
  ],
  "history": {
    "relative_start": {
      "template": "-{{days}}d"
    },
    "aggregate": {
      "constant": "aggregation_function"
    }
  }
}
```

The user will see two constants fields when they add this transformation to a
Signal: `days`, a number, and `aggregation_function`, a string from a list of
allowed values.

The `history` block tells the Pipeline to make a TSDB query and
attach the results of that query to the `POST /process` request. The inner keys
in that block define the TSDB query. The user-provided values for `days` and
`aggregation_function` are injected as the `relative_start` and `aggregate`
parameters, respectively.

If the values of the constants were `days=2` and `aggregation_function=max`,
the TSDB query would look like:
```lua
Tsdb.query({
  ...,
  relative_start = "-2d",
  aggregate = "max"
})
```

And the history data would be in the payload to `/process` like:

```json
{
  "history": {
    "$signal_id": [
      {
        "ts": "$timestamp",
        "value": "$value",
        "tags": {
          "$tag": "$tag_value"
        }
      }
    ]
  }
}
```

#### TSDB Query Parameters

Supported TSDB query parameters are:

* relative_start
* relative_end
* start_time
* end_time
* aggregate
* sampling_size

#### Value Formats

Values can be injected by the Pipeline via one of three methods:

1. value: the literal value to pass. e.g. "2"
1. constant: the user-provided constant value to pass. e.g. "days"
1. template: format one or more constants, where the constant is specified
  betwixt two sets of brackets (`{{$constant}}`). e.g. "-{{days}}d"
