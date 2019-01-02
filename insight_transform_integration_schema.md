# ExoSense™ Insight Transform Schema

**Document Status:** Draft

## Core Payload Objects

The two primary payloads encountered with Insights, the
[Insight Function Info](#insight-function-info) and [Signal Data](#signal-data) objects, are described
here in detail.

### Insight Function Info

> Reference [InsightInfo](./insight-template.yaml#L223) in the Swagger file

Insight Function Info is used to generate the ExoSense UI when adding a Function
to a Signal and to inform the ExoSense Pipeline on what information the Function
needs to calculate a result.

The object has the following keys:

Key           | Type    | Description
:-------------|---------|-------------
id            | string  | The unique ID used for this Function. Internal to the Insight Module.
name          | string  | The friendly name for this Function.
description   | string  | The description of this Function.
type          | string  | The type (transform, rule, or action) of this Function.
asynchronous  | boolean | Whether or not the Function requires callback info so that it can operate asynchronously.
history       | object  | Optionally attach timeseries data to `POST /process` calls.
constants     | array   | Specify parameters for users to provide when adding this Function.
inlets        | array   | Specify the Input Signals.
outlets       | object  | Specify the Output Signal.

#### Type

Insight Functions can be one of three types: transform, rule, or action. Their
classification into one of these buckets determines how ExoSense and the
Pipeline treats them. At time of writing, only transforms are supported
throughout the full stack.

#### Constants

Constants inform the ExoSense UI about parameters that users will supply when
they add the Function to one or more Signals. Each Constant in the `constants`
array can have the following properties:

Key           | Type    | Required            | Description
:-------------|---------|---------------------|-------------
name          | string  | true                | Name for this constant. Users will see this in the UI.
type          | string  | true                | The type of constant: value can be "string" or "number".
description   | string  | false               | Helpful description of this constant.
default       | --      | false               | Default value if left blank. Can be a string or a number, depending on `type`.
enum          | array   | false               | Array of allowed values.
maximum       | number  | false               | For number `type`, largest the value can be.
minimum       | number  | false               | For number `type`, smallest the value can be.

Example:

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
  ]
}
```

**TODO: See corresponding section on how Constants are received by Insight Functions.**

#### History

The Insight Function Info schema accepts a `history` parameter, which attaches
historical data from inlet Signals to the outgoing `POST /process` request. The
`history` block supports many Murano TSDB query parameters and the values of
those parameters can be injected in several ways by the Pipeline. First, an
example.

Your Function defines the following `constants` and `history` blocks:

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

##### TSDB Query Parameters

Supported TSDB query parameters are:

* relative_start
* relative_end
* start_time
* end_time
* aggregate
* sampling_size

##### Value Formats

Values can be injected by the Pipeline via one of three methods:

1. value: the literal value to pass. e.g. "2"
1. constant: the user-provided constant value to pass. e.g. "days"
1. template: format one or more constants, where the constant is specified
  betwixt two sets of brackets (`{{$constant}}`). e.g. "-{{days}}d"

### Signal Data

> Reference [SignalData](./insight-template.yaml#L321) in the Swagger file

## API Paths

There are three required paths that an Insight must support:

* `GET /info`: [Insight Module Info](#insight-info)
* `POST /insights`: [Function List](#function-list)
* `POST /process`: [Processing Signal Data](#processing-signal-data)

Optionally, an Insight can support the following paths:

* `GET /insight/{function_id}`: [Specific Function](#specific-function)
* `POST /lifecycle`: [Lifecycle Events](#lifecycle-events)

### Insight Module Info

> Reference [InsightInfoResults](./insight-template.yaml#L122) in the Swagger
> file

The `GET /info` endpoint serves to retrieve information about an Insight and
is expected to return the following payload keys:

Key                     | Type    | Description
:-----------------------|---------|-------------
name                    | string  | The friendly name for the Insight, which will be presented in the ExoSense UI.
description             | string  | High-level description of the Insight.
group_id_required       | boolean | Whether or not the result of `POST /insights` should be filtered based on a user-provided Group ID.
wants_lifecycle_events  | boolean | Whether or not the Insight requires lifecycle events to be sent.

Example:

```json
{
  "name": "Acme Co. Insight",
  "group_id_required": true,
  "description": "Insight exposing algorithms to predict the life of your Acme product.",
  "wants_lifecycle_events": true
}
```

### Function List

> Reference [InsightListResults](./insight-template.yaml#L286) in the Swagger
> file

The `POST /insights` endpoint returns a list of applicable Functions exposed by
the Insight and information about those Functions.

The request body can have the following keys:

Key         | Type    | Required | Description
:-----------|---------|----------|-------------
group_id    | string  | false    | Which group of Functions to return.
limit       | integer | false    | How many Functions to return.
offset      | integer | false    | Offset or paginate returned Functions.

Example:

```json
{
  "group_id": "CH00123",
  "limit": 4,
  "offset": 0
}
```

The response body should have the following keys:

Key         | Type    | Required | Description
:-----------|---------|----------|-------------
total       | integer | true     | The number of Functions in the group.
count       | integer | true     | The number of Functions returned.
insights    | array   | true     | Array of Function Info blocks, which will be presented by name in the ExoSense UI.
> See [Insight Function Info](#insight-function-info)

Example:

```js
{
  "total": 7,
  "count": 4,
  "insights": [
    { "name": "Function1", ... },
    { "name": "Function2", ... },
    { "name": "Function3", ... },
    { "name": "Function4", ... }
  ]
}
```

### Processing Signal Data

### Specific Function

### Lifecycle Events

## Reference & Definitions
