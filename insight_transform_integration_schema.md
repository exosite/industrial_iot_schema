# ExoSense™ Insight Transform Schema

## Core Payload Objects

The two primary payloads encountered with Insights, the [Insight Function Info](insight_transform_integration_schema.md#insight-function-info) and [Signal Data](insight_transform_integration_schema.md#signal-data) objects, are described here in detail.

### Insight Function Info

> Reference [InsightInfo](https://github.com/exosite/industrial_iot_schema/tree/2c23f7a5ddebc89a9869f9348154e4393adc9fbe/insight-template.yaml#L223) in the Swagger file

Insight Function Info is used to generate the ExoSense UI when adding a Function to a Signal and to inform the ExoSense Pipeline on what information the Function needs to calculate a result.

The object has the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| id | string | true | The unique ID used for this Function. Internal to the Insight Module. |
| name | string | true | The friendly name for this Function. |
| description | string | true | The description of this Function. |
| type | string | true | The type \(transform, rule, or action\) of this Function. |
| inlets | array | true | Specify the Input Signals. |
| outlets | object | true | Specify the Output Signal. |
| constants | array | false | Specify parameters for users to provide when adding this Function. |
| history | object | false | Optionally attach timeseries data to `POST /process` calls. |

#### Type

Insight Functions can be one of two types: transform, or rule. Their classification into one of these buckets determines how ExoSense and the Pipeline treats them.

#### Inlets

The `inlets` key is an array of Inlet objects, each of which can have the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| tag | string | true | Tag to use to identify the Inlet. Shows up in Signal Datapoint tags. |
| name | string | true | Friendly name for the Inlet. |
| description | string | true | Useful description for this Inlet. |
| data\_type | string | false | Optionally require specific data\_type. |
| data\_unit | string | false | Optionally require specific data\_unit. |
| primitive\_type | string | false | Optionally require specific primitive\_type. |

#### Outlets

The `outlets` key is _currently_ a single Outlet object, which can have the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| data\_type | string | true | Specify the output data\_type. |
| data\_unit | string | false | Optionally specify the output data\_unit. |

#### Constants

Constants inform the ExoSense UI about parameters that users will supply when they add the Function to one or more Signals. Each Constant in the `constants` array can have the following properties:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| name | string | true | Name for this constant. Users will see this in the UI. |
| type | string | true | The type of constant: value can be "string" or "number". |
| description | string | false | Helpful description of this constant. |
| default | -- | false | Default value if left blank. Can be a string or a number, depending on `type`. |
| enum | array | false | Array of allowed values. |
| maximum | number | false | For number `type`, largest the value can be. |
| minimum | number | false | For number `type`, smallest the value can be. |

Example:

```javascript
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

See [corresponding section](insight_transform_integration_schema.md#tags) on how Constants are received by Insight Functions

#### History

The Insight Function Info schema accepts a `history` parameter, which attaches historical data from inlet Signals to the outgoing `POST /process` request. The `history` block supports many Murano TSDB query parameters and the values of those parameters can be injected in several ways by the Pipeline. First, an example.

Your Function defines the following `constants` and `history` blocks:

```javascript
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

The user will see two constants fields when they add this transformation to a Signal: `days`, a number, and `aggregation_function`, a string from a list of allowed values.

The `history` block tells the Pipeline to make a TSDB query and attach the results of that query to the `POST /process` request. The inner keys in that block define the TSDB query. The user-provided values for `days` and `aggregation_function` are injected as the `relative_start` and `aggregate` parameters, respectively.

If the values of the constants were `days=2` and `aggregation_function=max`, the TSDB query would look like:

```lua
Tsdb.query({
  ...,
  relative_start = "-2d",
  aggregate = "max"
})
```

And the history data would be in the payload to `/process` like:

```javascript
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

**TSDB Query Parameters**

Supported TSDB query parameters are:

* relative\_start
* relative\_end
* start\_time
* end\_time
* aggregate
* sampling\_size

**Value Formats**

Values can be injected by the Pipeline via one of three methods:

1. value: the literal value to pass. e.g. "2"
2. constant: the user-provided constant value to pass. e.g. "days"
3. template: format one or more constants, where the constant is specified

   betwixt two sets of brackets \(`{{$constant}}`\). e.g. `-{{days}}d`

**Inlet Outlet Selection**

Normally, history is fetch for all inlets and outlets. If the function doesn't need both, the `include_from` key can be added. The value is `INLETS`, `OUTLETS`, or `BOTH`. When absent, it defaults to `BOTH`.

For example the snippet below will only get history for the inlet signals.

```text
{
  "history": {
    "include_from": "INLETS",
    "relative_start": {
      "template": "-{{days}}d"
    },
    "aggregate": {
      "constant": "aggregation_function"
    }
  }
}
```

### Signal Data

> Reference [SignalDataObjectArray](https://github.com/exosite/industrial_iot_schema/tree/2c23f7a5ddebc89a9869f9348154e4393adc9fbe/insight-template.yaml#L408) in the Swagger file

When an Insight Function receives Signal Data, the object the Function receives has three to five top-level keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| id | string | true | The ID of the Linkage this Signal Datapoint was sent from. |
| data | array | true | List of Signal Datapoints. |
| args | object | true | Information about the specific Insight including values for user-provided Constants. |
| history | object | false | If requested, history of Signals. Each Signal ID is the key, with an array of \(timestamp, value\) pairs. |
| cbi | object | false | If requested, an object containing the `url` to POST the results to, and a `token` to use in the authorization header. |

#### ID

The ID is the specific instance of the Insight Function. If an Asset has four signals—_A_, _B_, _C_, and _D_—and they are Inlets to a Transform Function like the following:

```text
A --\
     |-- Transform -- AB
B --/

C --\
     |-- Transform -- CD
D --/
```

Then the first and second Transforms will have different IDs. In the ExoSense Pipeline, these instances are known as Linkages, and the ID is the Linkage ID.

The ID field is critical for multiple-Inlet Insight Functions that do not use a `history` query, as that Function will receive the Inlet Signal Datapoints separately and will need to keep track of their relationships.

#### Data

> Reference [SignalData](https://github.com/exosite/industrial_iot_schema/tree/2c23f7a5ddebc89a9869f9348154e4393adc9fbe/insight-template.yaml#L321) in the Swagger file

Signal Data passed around ExoSense to and from an Insight has a common schema.

Signal Data objects have the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| origin | string | true | Publishing ID. |
| generated | string | true | Publishing ID that created this Signal Datapoint. |
| ts | integer | true | Unix timestamp in microseconds of when the data originated in Murano. |
| value | -- | true | Value for this instance of data. |
| tags | object | false | Tags helpful in identifying the original source of the data. |
| gts | integer | false | Unix timestamp in microseconds of when this Signal Datapoint was generated. |
| ttl | integer | false | Time to live for Signal Datapoint. |

**Tags**

Tags include general info about the Signal Datapoint as well as `inlet`, which ties an individual Datapoint back to its Inlet using the Inlet tag.

```javascript
{
  ...
  "tags": {
    "resource": "data_in",
    "pid": $product_id,
    "metric": $data_in_key,
    "identity": $device_identity,
    "data_unit": $data_unit,
    "data_type": $data_type,
    "primitive_type": $primitive_type,
    "inlet": $inlet_tag
  }
}
```

**Origin**

Origin describes the source of the Datapoint. Frequently this source is a Device Channel, but could also be from a Signal injection, in which case the Origin will be the UUID of the Signal.

The most common `origin` is in the following format:

```text
<PRODUCT_ID>.<DEVICE_ID>.<RESOURCE_ID>.<CHANNEL_ID>
```

For most situations in ExoSense, the `<RESOURCE_ID>` is `data_in`.

#### Args

The Args block in Signal Data contains the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| function\_id | string | true | ID of the Function. |
| group\_id | string | false | Group ID if one exists. |
| constants | object | false | Constant parameters. |

### Rules

* The value for `type` in the [Insight Function Info](insight_transform_integration_schema.md#insight-function-info) is `rule`.
* The [outlet data type](insight_transform_integration_schema.md#outlets) is `STATUS`

#### Example of Rule Insight Function Info

```text
{
    name: "SomeRule",
    description: "SomeRule description",
    type: "rule",
    constants: [
      {
        name: "const1",
        description: "desc for const1",
        type: "string"
      },
      {
        name: "level",
        description: "The alert level if the substring is found",
        type: "number",
        enum: [1, 2, 3, 4],
        default: 1
      }
    ],
    outlets: {
      primitive_type: "JSON",
      data_type: "STATUS",
    }
}
```

#### Status Data Type

The output of a rule insight is a JSON string.

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| level | integer | true | Alert severity |
| type | string | false |  |
| value | string | false |  |

#### Levels

| Level | Value |
| :--- | :--- |
| Normal | 0 |
| Info | 1 |
| Warning | 2 |
| Critical | 3 |
| Error | 4 |

#### User defined addendum messages
The notifications and rule event logs may include an extension message that can be added by an end user. To enable this per Rule function, the function must include the following reserved named constants.

```
  {
    name: "messageMatch",
    description: "Extra details for when value does match",
    type: "string",
  },
  {
    name: "messageElse",
    description: "Extra details for when value does not match",
    type: "string",
    default: "The value didn't match",
  },
```

Refer to [Constants](insight_transform_integration_schema.md#constants) for details on properties.

## API Paths

There are three required paths that an Insight must support:

* `GET /info`: [Insight Module Info](insight_transform_integration_schema.md#insight-info)
* `POST /insights`: [Function List](insight_transform_integration_schema.md#function-list)
* `POST /process`: [Processing Signal Data](insight_transform_integration_schema.md#processing-signal-data)

Optionally, an Insight can support the following paths:

* `GET /insight/{function_id}`: [Specific Function](insight_transform_integration_schema.md#specific-function)
* `POST /lifecycle`: [Lifecycle Events](insight_transform_integration_schema.md#lifecycle-events)

### Insight Module Info

> Reference [InsightInfoResults](https://github.com/exosite/industrial_iot_schema/tree/2c23f7a5ddebc89a9869f9348154e4393adc9fbe/insight-template.yaml#L122) in the Swagger file

The `GET /info` endpoint serves to retrieve information about an Insight and is expected to return the following payload keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| name | string | true | The friendly name for the Insight, which will be presented in the ExoSense UI. |
| description | string | true | High-level description of the Insight. |
| group\_id\_required | boolean | true | Whether or not the result of `POST /insights` should be filtered based on a user-provided Group ID. |
| wants\_lifecycle\_events | boolean | false | Whether or not the Insight requires lifecycle events to be sent. |

Example:

```javascript
{
  "name": "Acme Co. Insight",
  "group_id_required": true,
  "description": "Insight exposing algorithms to predict the life of your Acme product.",
  "wants_lifecycle_events": true
}
```

### Function List

> Reference [InsightListResults](https://github.com/exosite/industrial_iot_schema/tree/2c23f7a5ddebc89a9869f9348154e4393adc9fbe/insight-template.yaml#L286) in the Swagger file

The `POST /insights` endpoint returns a list of applicable Functions exposed by the Insight and information about those Functions.

The request body can have the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| group\_id | string | false | Which group of Functions to return. |
| limit | integer | false | How many Functions to return. |
| offset | integer | false | Offset or paginate returned Functions. |

Example:

```javascript
{
  "group_id": "CH00123",
  "limit": 4,
  "offset": 0
}
```

The response body should have the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| total | integer | true | The number of Functions in the group. |
| count | integer | true | The number of Functions returned. |
| insights | array | true | Array of Function Info blocks, which will be presented by name in the ExoSense UI. |

> See [Insight Function Info](insight_transform_integration_schema.md#insight-function-info)

Example:

```javascript
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

> Reference the [Signal Data section](insight_transform_integration_schema.md#signal-data) above

The `POST /process` endpoint will be called with the Signal Data as specified in the section above. What the Insight Function does with that payload is up to its author, but it is expected that this endpoint will return an array of arrays.

The inner array is for output [Signal Datapoints](insight_transform_integration_schema.md#data) for a specific Outlet. In the future, the outer array will be used to hold different Outlets' inner arrays.

A Function that returns nothing will respond with an empty array of arrays: `[[]]`.

### Specific Function

> Reference the [Insight Function Info section](insight_transform_integration_schema.md#insight-function-info) above

The `GET /insight/{function_id}` endpoint returns a single Function Info block corresponding to its member Function with the same `function_id`.

### Lifecycle Events

> Reference [LifecycleEvent](https://github.com/exosite/industrial_iot_schema/tree/2c23f7a5ddebc89a9869f9348154e4393adc9fbe/insight-template.yaml#L306) in the Swagger file.

The `POST /lifecycle` endpoint is optional and serves to inform the Insight about creation and deletion events.

This endpoint will receive a body with the following keys:

| Key | Type | Description |
| :--- | :--- | :--- |
| event | string | "create" or "delete" |
| id | string | The Linkage ID for this specific instance of the Insight Function |
| args | object | The same `args` object as sent to the [`/process` endpoint](insight_transform_integration_schema.md#args) |

## Reference & Definitions

| Term | Definition |
| :--- | :--- |
| Insight | Module of analytic Functions to perform calculations on Asset Signals. |
| Function | Member of an Insight. |
| Datapoint | Single instance of a Signal Data stream. |
| Linkage | ExoSense Pipeline term for non-Signal blocks on the Asset Config page of the UI. |

## Change log

* New document to detail insight transform and rule interface with ExoSense
