# ExoSense™️ Channel and Signal Data Schema


**Document Status:** Version 3.0 _Draft_

## Introduction
This document defines the information required to interface with ExoSense™️ from the “first mile” perspective of the connected device or gateway, as well as describing how this information is carried on into the “last mile” or client-side Application.

This document is meant for device developers building native support into the device or a proxy/gateway service for connection to ExoSense via an IoT service and for those looking to gain a deeper understanding of the architecture of channels and signals in the ExoSense environement.  It is not required for typical regular use of the ExoSense application itself.

### Definitions
The reader of this document should have a grasp on the following items or will need to for this document to make sense.

Term|Description|More Information
--|--|---
Murano|IoT Platform|[Murano Docs](https://docs.exosite.com)
ExoSense™️|Industrial IoT Application|
Device/Gateway|A thing with an IP Connection sending data to a platform|
Sensors|Conencted to Device/Gateway via wired or wireless protocol or IO| 
Channel|A individual piece information sent to ExoSense by a device.|Typically a sensor output and typically a device is sending many channels of data.
Signal|An ExoSense concept similiar to channel but as a part of a virtual Asset object.  Source is typically a device channel but doesn't have to be.|
Asset|An ExoSense concept for digitzing an Asset (a machine, system, eqiupment, etc)|
Fieldbus|Industrial protocols like Modbus TCP or RTU, J1939, CANOpen, etc|


## IoT Platform Device Interface Configuration Requirements

ExoSense uses the Murano IoT Platform device interface for it's device connectivity.  The following information details the specific resources used (HTTP resources / MQTT topics) regardless of the transport protocol  (MQTT or HTTP).

*Note: This document does not cover most details of how to interact with Murano’s IoT product/device interfaces including how to provision a device inside of a product defined in Murano, how to communicate with the [HTTP](http://docs.exosite.com/reference/products/device-api/http/) or [MQTT](http://docs.exosite.com/reference/products/device-api/mqtt/) APIs or other topics covered in [Murano’s public documentation](https://docs.exosite.com).*

**Device resource use is as follows:**

Resource Name|ExoSense Status|Who Can Write To|Description
--|--|--|---
data_in|supported|Device|Used to send data from device to cloud in the format defined in Section 4
config_io|supported|Device / App|Used to share the complete configuration for a channels in the product.  This should be a 2-way synchronization meaning in the case of a self-configuring gateway, this would be written to by the gateway.  In a gateway that requires manual configuration from the application, this would be read by the gateway and cached locally.
data_out|*planned*|App|To be defined in the future - used for writing commands to devices
config_oem|*reserved*|tbd|Settings for product names, and limits that constrain/override communications or collections of data per the manufacturers/OEMs requirements
config_applications|*reserved*|tbd|This will configure how each fieldbus or gateway control app behaves, and what is required to configure each channel that will utilize this application. (i.e. “interface = serial port 1”)
config_interfaces|*reserved*|tbd|This will configure how each fieldbus or gateway control app behaves, and what is required to configure each channel that will utilize this application. (i.e. “interface = serial port 1”)  
config_rules |*reserved*|tbd|Possibly to be defined in the future
config_network|*reserved*|tbd|Initial Concepts in Appendix, but not implemented


## Device / Gateway Channel Configuration Schema
This section defines the Channel Configuration object (sometimes called a device or gateway template).  This is the 'contract' for each individual device as to what channels of data it will be sending. The idea is data used by ExoSense flows as 'Channels' to and from devices.  These device channel sources can then be mapped as sources to Asset signals in the ExoSense application.

A gateway or device will require some level of configuration in order to do several things:

1.  Know what information to read off of a fieldbus or IO
2.  Translate that information from machine-readable and terse input to Murano, back into contextual and human readable data ready to be taken into ExoSense - i.e. a signal object
3.  Provides a consistent way for standardizing interfaces so that analytic apps downstream are able to consume this common data type.

Of note for this section - the channel (io) configuration will be stored in the config_io product resource for the device as defined in Section 2 of this document.  The value in that resource will be considered the source of truth for the shared gateway configuration.  Meaning if a gateway is re-configured manually at the gateway, or if it is a gateway that is autoconfigured by discovering the devices connected to it, the updated value must be pushed to that resource before RCM will become aware of any changes.

The configuration below wraps a user-defined value with a ${...}, and other names/keys are meant to be an exact match that will be used by ExoSense.  Some values for a key are filled in with example strings - noted with an “e.g.”.

**Channel Configuration Definition Description**
```yaml
# config_io channel definition 
last_edited: "{$date_timestamp}" # e.g. 2018-03-28T13:27:39+00:00 
last_editor" : "${edited_by}" # Person user name, "user", or "device"
meta : 
    #This is an open section for manufacturers to include useful meta info about the channels if they see fit
locked: ${locked_config_state} #NOT SUPPORTED YET, optional - Boolean, marks config as not editable by UI, assume false if not present
channels: # "device channel" as opposed to an "asset signal"
  ######### Example channel config 1 ############
  ${device_channel_id1}: # unique channel identifier
    display_name: "Human readable channel name" 
    description: "One-liner description (optional)",
    properties:
      data_type: "BINARY", # taken from dictionary of types
      value_mapping:
          0: "${lookup_key_name}" # e.g. "ON"
          1: "${lookup_key_name}" # e.g. "DOWN"
    protocol_config" : 
      application : "${fieldbus_logger_application_id}" # e.g. "Modbus_TCP"
      interface : "${path_to_interface}" # e.g. "/dev/eth0"
      app_specific_config :  # See section X for specific application configuration parameters
        ${app_specific_config_item1}" : "${config_item1_value}"
        ${app_specific_config_item2}" : "${config_item2_value}"
      sample_rate : "${sample_time_in_ms}" # required
      report_rate : "${report_time_in_ms}" # required - defaults to sample_rate
      report_on_change : "${true|false}" # optional - default false (always report on start-up)
  ######### Example channel config 2 ############
  ${device_channel_id2}:   # real number type channel
      display_name: "e.g. Temperature Setting"
      description: "e.g. Temperature setting for a thing I have."
      properties: 
        data_type: "${defined_type_name}" # See "types" section - in this case it would be "TEMPERATURE"
        min: 16  # channel value min
        max: 35  # channel value max
        precision: 2 
        data_unit: "${unit_enum}" # Enumerated lookup to unit types for the given type
        device_diagnostic: false # Tells RCM that this is a “meta” signal that describes an attribute of the devices health
      protocol_config : 
        application : "${fieldbus_logger_application_name}" # e.g. "Modbus_RTU"
        interface : "${path_to_interface}" # e.g. "/dev/tty0/"
        app_specific_config : {
          ${app_specific_config_item1} : ${app_config_item1_value}"
          ${app_specific_config_item2}" : "${config_item2_value}"
        input_raw : 
          max : ${raw_input_max} # (future) optional - above this puts the channel in error
          min : ${raw_input_max} # (future) optional - above this puts the channel in error
          unit : "${raw_input_units}" # (future) optional - e.g. "mA", reference only
        multiplier : ${number_to_be_multiplied_into_the_raw_value}" # If not present set to 1
        offset : "${offset}" # if not present assume 0
        sample_rate : ${sample_time_in_ms} #required
        report_rate : ${report_time_in_ms} # required - defaults to sample_rate
        down_sample : "${MIN|MAX|AVG|ACT}" # Minimum in window, Maximum in window, running average in window, or actual value (assume report rate = sample rate)
        report_on_change : "${true|false}" # optional - default false (always report on start-up)
```
**Example config_io (JSON format)**
```json
"last_edited": "2018-03-28T13:27:39+00:00 ",
"last_editor" : "user",
"meta" : {},
"locked": false,
"channels": {
  "001": {
    "display_name": "Input State",
    "description": "Machine Input State Information",
    "properties": {
      "data_type": "BINARY",
      "value_mapping": {
          "0": "ON",
          "1": "DOWN"  
      }
    },
    "protocol_config" : {
      "application" : "Modbus_TCP",
      "interface" : "/dev/eth0",
      "app_specific_config" : {
        
      },
      "sample_rate" : 5000,
      "report_rate" : 5000,
      "report_on_change" : false,
    },
  },
  "002": {
      "display_name": "Temperature",
      "description": "Temperature Sensor Reading",
      "properties": {
        "data_type": "TEMPERATURE",
        "min": 16,
        "max": 35,
        "precision": 2,
        "data_unit": "DEG_CELSIUS",
        "device_diagnostic": false,
      },
      "protocol_config" : {
        "application" : "Modbus_RTU",
        "interface" : "/dev/tty0/",
        "app_specific_config" : {
          
        },
        "input_raw" : {
          "max" : 0,
          "min" : 20,
          "unit" : "mA"
        },
        "sample_rate" : 2000,
        "report_rate" : 10000, 
        "down_sample" : "AVG",
        "report_on_change" : false,
    }
  }
}
```
**Notes:**
1. Report on change assumes that the report rate is still used and observed (e.g. 10 minutes) but if report on change is set to true, then it will send on any changes outside the typical 10 minute report rate
2. Report on change is by default false
3. Channel IDs must be unique in the device context.  (the RCM context for globally unique will be: “product ID” + “device id” + “channel id”
4. Channel IDs can be any valid string.  At this time, if RCM generates a channel ID from the UI it will be in the form of a UUID.

More Examples can be found below

#### Configuration Schema To-Do
> _1. Support for controlling 'who' can edit a channel to lock specific channels down to not be able to be modified via the application_
> 
>



## Device Data Transport Schema
Having a common shared channel configuration (a contract essentially) between the device and the cloud/application allows us to keep the actual data sent betwee devices and the cloud to a minimum - focusing only on the sending of values for channels rather than unecesary configuration information that rarely changes.  

The resource used for writing channel values from devices to the cloud/application is “data_in”, as mentioned in the resource section.

> _Note: A future consideration moving beyond “monitoring” to control - we would add a second resource in Murano called “data_out” when the cloud UI writes a value to the gateway to change an actuator value._

There are 3 different scenarios of how we might want to send data - each one should build on the other, and they are:

**Single Data Value**

This is a very simple signal_id = value approach, but encoded in JSON.

```
{ "${device_channel_id1}" : "${current_channel_value}" }
```


**Multiple signals written in a single payload**

```
{
  "${device_channel_id1}" : "${current_channel_value1}",
  "${device_channel_id2}" : "${current_channel_value2}"
}
```

This payload assumes each datapoint is to be recorded in the time series database at the time it is received.

**Multiple signals, with some repeating, with different timestamps in a single payload:**

Utilize the Record API from Murano, and apply the array of signals to each timestamps data. 

[Murano Device Record API - HTTP](http://docs.exosite.com/reference/products/device-api/http/#record)

[Murano Device Record API - MQTT](http://docs.exosite.com/reference/products/device-api/mqtt/#report-data-to-historical-timestamps) 


This requires that the clock be sync’d on the gateway to the global network time via ntp which is used by our servers in our cluster. Our recommendation will be that the ntp server syncs with the gateway at least once every time the power is cycled on the gateway, and once per 12-24 hours of continuous operation time.

### Channel Error Handling
*Special Considerations for Errors*

When an error occurs for a signal, the payload will change by adding the protected keyword property `__error` to the JSON root object like so:

```json
{
  "${channel_id1}" : "${current_channel_value1}",
  "${channel_id2}" : "${current_channel_value2}",
  "__error" : {
    "${channel_id1}" : "${error_message_or_code}",
    "${channel_id3}" : "${error_message_or_code}" 
  }
}
```

The error object is a list of keys of the channel ids with an error, and then the value of that property is the error message, error code, or concatenation of any useful information that can be formatted into a string.

_Note: the device can report a channel data payload, even if the data is erroneous, but that is optional.  We will accept a chanel value and an error, just an error for a channel, or just a value.  All combinations are supported._

## Data Type Definitions

For each channel there is a specific type, which signals inherit from the channel.  This type relates to the units of the channel/signal value, format, and the possible values for a given signal.  Each of these types stem from one of the four primitive types.

In the section below we will begin to note what comprises a “type”, and what the different types are.

The break neatly into two categories: 

1.  State representation - a finite number of states a channel value can be
2.  Real Number & Strings - unlimited measurement of the magnitude of a signal that doesn’t not correspond to any discrete states

Below we will discuss features of each category of signal, and list all the properties and each available type.  One common shared property across all of these various types is “min” and “max”.  This is considered optional, and is used to be absolute ranges, not an alarm trigger, and won’t be enumerated for each type.

_NOTE: Anything in the following 2 subsections that isn’t given a “Type Key Name”, or a table of properties and their related values, is considered to be a future consideration for inclusion._

### Primitive Types

A primitive type describes the actual underlying encoding used for values.  There are four primitive types: `NUMERIC`, `STRING`, `JSON`, `BOOLEAN`.

###  	State Representation Types

There are only two main types of signals that can represent state, but both have a requirement that the values aren’t fixed in their labeling, which means they must be defined per-signal.

Type|Key<br>(`data_type`)|Required Property|Accpted Values|Notes
--|--|--|--|--
#### Binary
Key (`data_type`): BINARY<br>
Accepted Units (`data_unit`): Not used<br>
Primitive Type (`primitive_type`): NUMERIC, BOOLEAN, STRING
Required Property: `value_mapping`<br>
Accepted Values: For NUMERIC, 1 or 0.  For BOOLEAN, true or false.  For STRING, a value from `value_mapping`<br>
Notes: Strings such as ON,OFF,UP,DOWN,START,STOP

**Example Binary Channel**
```json


```


#### Categorical
Key (`data_type`): CATEGORICAL<br>
Accepted Units (`data_unit`): Not used<br>
Primitive Type (`primitive_type`): NUMERIC, STRING
Required Property: `value_mapping`<br>
Accepted Values: For NUMERIC, a key from `value_mapping`.  For STRING, a value from `value_mapping`<br>
Notes: Strings such as ON, OFF, UP, DOWN, START, STOP, STOPING, RUNNING, ROTATING, IDLE

**Example Categorical Channel**
```json


```

### Generic Types
For data that may not have units, anything that is dimensionless, or no supported unit types exist. Includes numeric, string, and structured data generic types.

#### String (unitless)
Key (`data_type`): STRING<br>
Accepted Units (`data_unit`): Not Used<br>
Primitive Type (`primitive_type`): STRING<br>
UI Unit Abbreviation: na<br>
Notes: Any string

**Example String Channel**
```json


```

#### JSON (unitless)
Key (`data_type`): JSON<br>
Accepted Units (`data_unit`): Not Used<br>
Primitive Type (`primitive_type`): JSON<br>
UI Unit Abbreviation: na<br>
Notes: Any JSON blob

**Example JSON Channel**
```json


```

#### Number (unitless)
Key (`data_type`): NUMBER<br>
Accepted Units (`data_unit`): Not Used<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: na<br>
Notes: Any Real Number

**Example Number Channel**
```json


```


*Note: Generic types without accepted unit types will not be able to take advantage of unit conversion and other unit specific functionality in ExoSense.*

### Unit Orignated Types
The following assume a fixed unit type is provided as a part of the origination and that would carry through the system.

Many of these types will represent base physical measurements (temperature, length, etc), or derived measurements (velocity), as noted in this [Wikipedia article](https://en.wikipedia.org/wiki/List_of_physical_quantities).

#### Abasement
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Acceleration
Key (`data_type`): ACCELERATION<br>
Accepted Units (`data_unit`): METER_PER_SEC2<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Absorbed dose rate
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Amount of Substance
Key (`data_type`): AMOUNT<br>
Accepted Units (`data_unit`): MOLE<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Angular acceleration
Key (`data_type`): ANGULAR_ACCEL<br>
Accepted Units (`data_unit`): RAD_PER_SEC2, ROTATIONS_PER_MIN2, DEG_PER_SEC2<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Angular momentum
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Angular Speed / Velocity
Key (`data_type`): ANGULAR_VEL<br>
Accepted Units (`data_unit`): RAD_PER_SEC, ROTATIONS_PER_MIN, DEG_PER_SEC<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Area
Key (`data_type`): AREA<br>
Accepted Units (`data_unit`): METER2, KILOMETER2, FEET2, INCH2, MILE2<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Area density
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Capacitance
Key (`data_type`): CAPACITANCE<br>
Accepted Units (`data_unit`): FARAD<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Catalytic activity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Catalytic activity concentration
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Chemical Potential
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Crackle
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Currency
Key (`data_type`): CURRENCY<br>
Accepted Units (`data_unit`): AFN, ALL, DZD, USD, EUR, AOA, XCD, ARS, AMD, AWG, AUD, AZN, BSD, BHD, BDT, BBD, BYR, BZD, XOF, BMD, BTN, INR, BOB, BOV, BAM, BWP, NOK, BRL, BND, BGN, BIF, CVE, KHR, XAF, CAD, KYD, CLF, CLP, CNY, COP, COU, KMF, CDF, NZD, CRC, HRK, CUC, CUP, ANG, CZK, DKK, DJF, DOP, EGP, SVC, ERN, ETB, FKP, FJD, XPF, GMD, GEL, GHS, GIP, GTQ, GBP, GNF, GYD, HTG, HNL, HKD, HUF, ISK, IDR, XDR, IRR, IQD, ILS, JMD, JPY, JOD, KZT, KES, KPW, KRW, KWD, KGS, LAK, LBP, LSL, ZAR, LRD, LYD, CHF, MOP, MKD, MGA, MWK, MYR, MVR, MRU, MUR, XUA, MXN, MXV, MDL, MNT, MAD, MZN, MMK, NAD, NPR, NIO, NGN, OMR, PKR, PAB, PGK, PYG, PEN, PHP, PLN, QAR, RON, RUB, RWF, SHP, WST, STN, SAR, RSD, SCR, SLL, SGD, XSU, SBD, SOS, SSP, LKR, SDG, SRD, SZL, SEK, CHE, CHW, SYP, TWD, TJS, TZS, THB, TOP, TTD, TND, TRY, TMT, UGX, UAH, AED, USN, UYI, UYU, UZS, VUV, VEF, VND, YER, ZMW, ZWL<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: Currency codes (based on list found here: https://www.iban.com/currency-codes.html) 

#### Current density
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Density
Key (`data_type`): DENSITY<br>
Accepted Units (`data_unit`): KG_PER_M3<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Dose equivalent
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Dynamic viscosity
Key (`data_type`): DYNAMIC_VISCOSITY<br>
Accepted Units (`data_unit`): CENTISTOKES, METERS2_PER_SEC<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Electric Charge
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Electric Charge Density
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Electric Current
Key (`data_type`): ELEC_CURRENT<br>
Accepted Units (`data_unit`): AMPERE, MILLIAMP, MICROAMP<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Electric Displacement
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Electric Field Strength
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Electrical Conductance
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Electrical Conductivity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Electrical Potential
Key (`data_type`): ELEC_POTENTIAL<br>
Accepted Units (`data_unit`): VOLT, MILLIVOLT, MICROVOLT, KILOVOLT, MEGAVOLT<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Electrical Resistance
Key (`data_type`): ELEC_RESISTANCE<br>
Accepted Units (`data_unit`): OHM, MILLIOHM, MICROOHM, KILOOHM, MEGAOHM<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Electrical resistivity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Energy
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Energy density
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Entropy
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Flow (Volumetric)
Key (`data_type`): FLOW<br>
Accepted Units (`data_unit`): METERS3_PER_SEC, PERCENT, SCFM, LITERS_PER_SEC, LITERS_PER_MIN, GALLONS_PER_SEC, GALLONS_PER_MIN<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Flow (Mass)
Key (`data_type`): FLOW_MASS<br>
Accepted Units (`data_unit`): KILO_PER_SEC, LBS_PER_SEC<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Force
Key (`data_type`): FORCE<br>
Accepted Units (`data_unit`): NEWTON<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Frequency
Key (`data_type`): FREQUENCY<br>
Accepted Units (`data_unit`): HERTZ, KHZ, MHZ<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Fuel efficiency
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### GPS / Location
Key (`data_type`): LOCATION<br>
Accepted Units (`data_unit`): LAT_LONG, LAT_LONG_ALT<br>
Primitive Type (`primitive_type`): JSON<br>
UI Unit Abbreviation: --<br>
Notes: --

**JSON payload example:**
```json
{"lat": "{value}","lng":"{value}","alt":"{value}","acc":"{value}"}
```

#### Half-life
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Heat
Key (`data_type`): HEAT<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Heat capacity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Heat flux density
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Humidity
Key (`data_type`): HUMIDITY<br>
Accepted Units (`data_unit`): PERCENT<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: %<br>
Notes: --

#### Illuminance
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Impedance
Key (`data_type`): IMPEDANCE<br>
Accepted Units (`data_unit`): OHM, KILOOHM, MEGAOHM<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Impulse
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Inductance
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Irradiance
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Intensity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Jerk
Key (`data_type`): JERK<br>
Accepted Units (`data_unit`): METER_PER_SEC3<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Jounce
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Length
Key (`data_type`): LENGTH<br>
Accepted Units (`data_unit`): METERS, CENTIMETERS, KILOMETERS, MILLIMETERS, FEET, INCH, YARD, MILES, MICRONS<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Linear density
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Luminous Intensity
Key (`data_type`): LUMINOUS_INTENSITY<br>
Accepted Units (`data_unit`): CANDELA<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Luminious flux
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Magnetic field strength
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Magnetic flux
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Magnetic flux density
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Magnetization
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Mass
Key (`data_type`): MASS<br>
Accepted Units (`data_unit`): MILLIGRAM, GRAM, KILOGRAM, POUND, OZ, TON, METRIC_TON<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Mass fraction
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Mean lifetime
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Molar concentration
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Molar energy
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Molar entropy
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Molar heat capacity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Moment of inertia
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Momentum
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Percentage
Key (`data_type`): PERCENTAGE<br>
Accepted Units (`data_unit`): PERCENT<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: %<br>
Notes: --

#### Permeability
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Permittivity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Plane angle
Key (`data_type`): ANGLE<br>
Accepted Units (`data_unit`): RADIAN, DEGREE, ARCMINUTE, ARCSECOND<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Power
Key (`data_type`): POWER<br>
Accepted Units (`data_unit`): WATT, MILLIWATT, KILOWATT, MEGAWATT<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Pressure
Key (`data_type`): PRESSURE<br>
Accepted Units (`data_unit`): MBAR, BAR, PSI, TORR, PASCAL, ATMOSPHERE<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Pop
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Radioactive Activity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Radioactive Dose
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Radiance
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Radiant intensity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Reaction rate
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Refraction rate
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Refractive index
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Solid angle
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Speed
Key (`data_type`): SPEED<br>
Accepted Units (`data_unit`): METER_PER_SEC, MPH, KPH, IN_PER_SEC<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Specific Energy
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Specific heat capacity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Specific Volume
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Spin
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Strain
Key (`data_type`): STRAIN<br>
Accepted Units (`data_unit`): PERCENT<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: %<br>
Notes: --

#### Stress
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Surface tension
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Temperature
Key (`data_type`): TEMPERATURE<br>
Accepted Units (`data_unit`): KELVIN, DEG_FAHRENHEIT, DEG_CELSIUS, RANKINE<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Thermal conductivity
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Time
Key (`data_type`): TIME<br>
Accepted Units (`data_unit`): SECONDS, MILLISECOND, MINUTE, HOUR, DAY, YEAR<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Torque
Key (`data_type`): TORQUE<br>
Accepted Units (`data_unit`): NEWTON_METER, POUND_FOOT<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Velocity
Key (`data_type`): VELOCITY<br>
Accepted Units (`data_unit`): METER_PER_SEC<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Volume
Key (`data_type`): VOLUME<br>
Accepted Units (`data_unit`): METER3, FEET3, LITRE, GALLON, PINT, INCH3, CENTIMETER3<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Wavelength
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Wavenumber
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Wavevector
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported

#### Weight
Key (`data_type`): WEIGHT<br>
Accepted Units (`data_unit`): NEWTON, POUND<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: --

#### Work
Key (`data_type`): --<br>
Accepted Units (`data_unit`): --<br>
Primitive Type (`primitive_type`): NUMERIC<br>
UI Unit Abbreviation: --<br>
Notes: not supported


## Device Channel Protocol Interfaces
This section defines the supported protocol interfaces and parameters.

### Modbus TCP

Parameters for a channel's 'app_specific_config' field when using Modbus_TCP.
```yaml 
    ip_address : "IP_ADDRESS" # ip where the channel is being read as a string
    port : "INTEGER" # port to make the request on
    register_range : ["INPUT_COIL", "HOLDING_COIL", "INPUT_REGISTER", "HOLDING_REGISTER"]
    register_offset : "INTEGER" # [1-4]0000-[1-4]9999
    register_count : "INTEGER" # 1, 2, 4, 8, ...
    byte_endianness" : [ "little", "big" ]
    register_endianness" : [ "little", "big" ]
    evaluation_mode : ["floating point: ieee754", "whole-remainder", "signed integer", "unsigned", "bitmask_int", "bitmask_bool", "string-ascii-byte", "string-ascii-register"]               
    bitmask : "HEXADECIMAL" # hex value for bits to mask out/pass-thru
```


### Modbus RTU

Parameters for a channel's 'app_specific_config' field when using Modbus_TCP.
```yaml 
    slave_id : "INTEGER" 
    register_range : ["INPUT_COIL", "HOLDING_COIL", "INPUT_REGISTER", "HOLDING_REGISTER"]
    register_offset : "INTEGER" # [1-4]0000-[1-4]9999
    register_count : "INTEGER" # 1, 2, 4, 8, ...
    byte_endianness" : [ "little", "big" ]
    register_endianness" : [ "little", "big" ]
    evaluation_mode : ["floating point: ieee754", "whole-remainder", "signed integer", "unsigned", "bitmask_int", "bitmask_bool", "string-ascii-byte", "string-ascii-register"]               
    bitmask : "HEXADECIMAL" # hex value for bits to mask out/pass-thru
```

### CANopen

Parameters for a channel's 'app_specific_config' field when using CANopen.
```yaml
    node_id : "HEXADECIMAL" # e.g. "0x01"
    msg_index : "HEXADECIMAL"  # "PDO" starts at 0x180,"SDO" starts at 0x580, required
    offset : "INTEGER" # e.g. "0" bytes (determines starting byte position to read), default is 0, required
    data_length : "INTEGER" # e.g. "8" bytes (determines how many PDOs to read), default is 8, required
    evaluation_mode : [“REAL32”, “INT8”, “INT16”, “UINT16”, “UINT32”, “STRING”, “BOOLEAN”]
    bitmask : "HEXADECIMAL" # optional, hex value for bits to mask out/pass-thru 
```
