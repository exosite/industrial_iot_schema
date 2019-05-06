# ExoSense™ Insight Rule Schema

**Document Status:** V1.0 Draft

## Rule Description

Insight Rule is almost same as custom insight transform. Please refer to [ExoSense™ Insight Transform Schema](insight_transform_integration_schema.md) for basic concept. 

The difference between Insight Transform are
* The value in `type` in [Insight Function Info](insight_transform_integration_schema.md#insight-function-info) is `rule`.
* The outlet data type is `STATUS`

### Example of Rule Insight Function Info

```
{
    name: 'SomeRule',
    description: 'SomeRule description',
    type: 'rule',       // type is `rule`
    constants: [
      {
        name: 'const1',
        description: 'desc for const1',
        type: 'string'
      },
      {
        name: 'level',
        description: 'The alert level if the substring is found',
        type: 'number',
        enum: [1, 2, 3, 4],
        default: 1
      },
    ],
    outlets: {
      primitive_type: 'JSON',
      data_type: 'STATUS',
    },
}
```

## data_type STATUS 

The output of a rule insight is a JSON string. 

Key           | Type    | Required | Description
:-------------|---------|----------|:------------
level         | integer | true     | Represent status. 
type          | string  | false    | TBD
value         | string  | false    | 

### Level Enum Table

Level         | Value   
:-------------|---------
Normal        | 0       
Info          | 1       
Warning       | 2       
Critical      | 3       
Error         | 4       
