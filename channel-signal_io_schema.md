# ExoSense™️ Channel and Signal Data Schema


**Document Status:** Version 2.2 _Draft_

## 1. Introduction
This document defines the information required to interface with ExoSense™️ from the “first mile” perspective of the connected device or gateway, as well as describing how this information is carried on into the “last mile” or client-side APIs and Application.

This document will not cover how to interact with Murano’s product/device interfaces, including how to provision a device inside of a product defined in Murano, how to communicate with the [HTTP](http://docs.exosite.com/reference/products/device-api/http/) or [MQTT](http://docs.exosite.com/reference/products/device-api/mqtt/) interfaces or other topics covered in [Murano’s public documentation](https://docs.exosite.com).  It will however cover how to use some of these interfaces in certain situations, and will define a standard product resource list.

### Definitions
The reader of this document should have a grasp on the following items or will need to for this document to make sense.

Term|Description|More Information
--|--|---
Murano|Exosite's IoT Platform|[Murano Docs](https://docs.exosite.com)
ExoSense™️|Industrial IoT Application|Built on top of Murano
Device/Gateway|A thing with a IP Connection sending data to a platform|
Sensors|Conencted to Device/Gateway via wired or wireless protocol or IO| 
Channel|A individual piece information sent to ExoSense by a device.|Typically a sensor output and typically a device is sending many channels of data.
Signal|An ExoSense concept similiar to channel but as a part of a virtual Asset object.  Source is typically a device channel but doesn't have to be.|
Asset|An ExoSense concept for digitzing an Asset (a machine, system, eqiupment, etc)|
Fieldbus|Industrial protocols like Modbus TCP or RTU, J1939, CANOpen, etc|


## Murano Device Interface Configuration Requirements

The Murano Product Solution interface requires the following specific resources are setup regardless of the connection type (MQTT, HTTP, etc)
These resources are are:

Resource Name|Status|Cloud Writable|Description
--|--|--|---
data_in|supported|yes|Used to send the live data in the format defined in Section 4
config_io|supported|yes|Used to share the complete configuration for a channels in the product.  This should be a 2-way synchronization meaning in the case of a self-configuring gateway, this would be written to by the gateway.  In a gateway that requires manual configuration from the application, this would be read by the gateway and cached locally.
data_out|*planned*|yes|To be defined in the future - used for writing commands to devices
config_oem|*reserved*|tbd|Settings for product names, and limits that constrain/override communications or collections of data per the manufacturers/OEMs requirements
config_applications|*reserved*|tbd|This will configure how each fieldbus or gateway control app behaves, and what is required to configure each channel that will utilize this application. (i.e. “interface = serial port 1”)
config_interfaces|*reserved*|tbd|This will configure how each fieldbus or gateway control app behaves, and what is required to configure each channel that will utilize this application. (i.e. “interface = serial port 1”)  
config_rules |*reserved*|tbd|Possibly to be defined in the future
config_network|*reserved*|tbd|Initial Concepts in Appendix, but not implemented
raw_data|*deprecated*|-|Replaced by data_in



## Device/Gateway Channel Configuration Schema
This section defines the Channel Configuration object (sometimes called a device or gateway template).  The idea is data used by ExoSense flows as 'Channels' to and from devices.  These device channel sources can then be mapped to Asset signals.

A gateway or device will require some level of configuration in order to do several things:

1.  Know what information to read off of a fieldbus or IO
2.  Translate that information from machine-readable and terse input to Murano, back into contextual and human readable data ready to be taken into ExoSense - i.e. a signal object
3.  Provides a consistent way for standardizing interfaces so that analytic apps downstream are able to consume this common data type.

Of note for this section - the channel (io) configuration will be stored in the config_io product resource for the device as defined in Section 2 of this document.  The value in that resource will be considered the source of truth for the shared gateway configuration.  Meaning if a gateway is re-configured manually at the gateway, or if it is a gateway that is autoconfigured by discovering the devices connected to it, the updated value must be pushed to that resource before RCM will become aware of any changes.

The configuration below wraps a user-defined value with a ${...}, and other names/keys are meant to be an exact match that will be used by ExoSense.  Some values for a key are filled in with example strings - noted with an “e.g.”.

**Channel Configuration Definition**
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
**Example config_io in JSON format**
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
When the gateway and cloud share a common configuration definition we can omit any of the unchanged or information that won’t change on an update for a value that has changed since the last sensor reading.

To that end, we want to define how the over-the-wire information will be sent after the configuration is shared in both places.
In this section we assume that a single Murano resource exists for writing all data from the gateway to the cloud - it will be referred to going forward as “data_in” - which is a common name used on many projects previously.

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
Special Considerations for Errors
When an error occurs for a signal, the payload will change by adding the protected keyword property “error” to the JSON root object like so:

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

For each data point there is a possible type, which predominantly relates to the units of the signal value, and the possible values for a given signal.

In the section below we will begin to note what comprises a “type”, and what the different types are.

The break neatly into two categories: 

1.  State representation - a finite number of states a channel value can be
2.  Real Number & Strings - unlimited measurement of the magnitude of a signal that doesn’t not correspond to any discrete states

Below we will discuss features of each category of signal, and list all the properties and each available type.  One common shared property across all of these various types is “min” and “max”.  This is considered optional, and is used to be absolute ranges, not an alarm trigger, and won’t be enumerated for each type.

_NOTE: Anything in the following 2 subsections that isn’t given a “Type Key Name”, or a table of properties and their related values, is considered to be a future consideration for inclusion._

###  	State Representation Types

There are only two main types of signals that can represent state, but both have a requirement that the values aren’t fixed in their labeling, which means they must be defined per-signal.

Type|Key<br>(`data_type`)|Required Property|Accpted Values|Notes
--|--|--|--|--
Binary|BINARY|`value_mapping`|Any string, or from list of common enumerated types: ON,OFF,UP,DOWN,START,STOP|An integer value - typically 1 or 0 sent from devices, OR exact match string.
Categorical|CATEGORICAL|`value_mapping`|Any string, or from list of common enumerated types|Integer value, or exact match string.  Future: Evaluate if it is useful to have translated words for common multi-state values - e.g. ON, OFF, UP, DOWN, START, STOP, STOPING, RUNNING, ROTATING, IDLE


**Example Binary Channel**
```json


```

**Example Categorical Channel**
```json


```

### Generic Types
For data that may not have units, anything that is dimensionless, or no supported unit types exist. Includes numeric, string, and structured data generic types.

Type|Key<br>(`data_type`)|Accepted Units<br> (`data_unit`)|UI Unit Abbreviation|Notes
--|--|--|--|--
String (unitless)|STRING|Not Used|na|Any string
JSON (unitless)|JSON|Not Used|na|Any JSON blob
Number (unitless)|Number|Not Used|na|Any Real Number

*Note: Generic types without accepted unit types will not be able to take advantage of unit conversion and other unit specific functionality in ExoSense.*

#### Examples
**Example String Channel**
```json


```


**Example Number Channel**
```json


```

**Example JSON Channel**
```json


```
### Unit Orignated Types
The following assume a fixed unit type is provided as a part of the origination and that would carry through the system.

Many of these types will represent base physical measurements (temperature, length, etc), or derived measurements (velocity), as noted in this [Wikipedia article](https://en.wikipedia.org/wiki/List_of_physical_quantities).

Type|Key<br>(`data_type`)|Accepted Units<br> (`data_unit`)|UI Unit Abbreviation|Notes
--|--|--|--|--
Abasement|--|--|--|not supported
Acceleration|ACCELERATION|METER_PER_SEC2|--
Absorbed dose rate|--|--|--|not supported
Amount of Substance|AMOUNT|MOLE|--|--
Angular acceleration|ANGULAR_ACCEL|RAD_PER_SEC2<br> ROTATIONS_PER_MIN2<br>DEG_PER_SEC2|--|--
Angular momentum|--|--|--|not supported
Angular Speed / Velocity|ANGULAR_VEL|RAD_PER_SEC<br>ROTATIONS_PER_MIN<br>DEG_PER_SEC|--|--
Area|AREA|METER2<br>KILOMETER2<br>FEET2<br>INCH2<br>MILE2|--|--
Area density|--|--|--|not supported
Capacitance|CAPACITANCE|FARAD|--|--
Catalytic activity|--|--|--|not supported
Catalytic activity concentration|--|--|--|not supported
Chemical Potential|--|--|--|not supported
Crackle|--|--|--|not supported
Currency|CURRENCY|AFN, ALL, DZD, USD, EUR, AOA, XCD, ARS, AMD, AWG, AUD, AZN, BSD, BHD, BDT, BBD, BYR, BZD, XOF, BMD, BTN, INR, BOB, BOV, BAM, BWP, NOK, BRL, BND, BGN, BIF, CVE, KHR, XAF, CAD, KYD, CLF, CLP, CNY, COP, COU, KMF, CDF, NZD, CRC, HRK, CUC, CUP, ANG, CZK, DKK, DJF, DOP, EGP, SVC, ERN, ETB, FKP, FJD, XPF, GMD, GEL, GHS, GIP, GTQ, GBP, GNF, GYD, HTG, HNL, HKD, HUF, ISK, IDR, XDR, IRR, IQD, ILS, JMD, JPY, JOD, KZT, KES, KPW, KRW, KWD, KGS, LAK, LBP, LSL, ZAR, LRD, LYD, CHF, MOP, MKD, MGA, MWK, MYR, MVR, MRU, MUR, XUA, MXN, MXV, MDL, MNT, MAD, MZN, MMK, NAD, NPR, NIO, NGN, OMR, PKR, PAB, PGK, PYG, PEN, PHP, PLN, QAR, RON, RUB, RWF, SHP, WST, STN, SAR, RSD, SCR, SLL, SGD, XSU, SBD, SOS, SSP, LKR, SDG, SRD, SZL, SEK, CHE, CHW, SYP, TWD, TJS, TZS, THB, TOP, TTD, TND, TRY, TMT, UGX, UAH, AED, USN, UYI, UYU, UZS, VUV, VEF, VND, YER, ZMW, ZWL|--|Currency codes (based on list found here: https://www.iban.com/currency-codes.html) 
Current density|--|--|--|not supported
Density|DENSITY|KG_PER_M3|--|--
Dose equivalent|--|--|--|not supported
Dynamic viscosity|DYNAMIC_VISCOSITY|CENTISTOKES<br>METERS2_PER_SEC|--|--
Electric Charge|--|--|--|not supported
Electric Charge Density|--|--|--|not supported
Electric Current|ELEC_CURRENT|AMPERE<br>MILLIAMP<br>MICROAMP|--|--
Electric Displacement|--|--|--|not supported
Electric Field Strength|--|--|--|not supported
Electrical Conductance|--|--|--|not supported
Electrical Conductivity|--|--|--|not supported
Electrical Potential|ELEC_POTENTIAL|VOLT<br>MILLIVOLT<br>MICROVOLT<br>KILOVOLT<br>MEGAVOLT|--|--
Electrical Resistance|ELEC_RESISTANCE|OHM<br>MILLIOHM<br>MICROOHM<br>KILOOHM<br>MEGAOHM|--|--
Electrical resistivity|--|--|--|not supported
Energy|--|--|--|not supported
Energy density|--|--|--|not supported
Entropy|--|--|--|not supported
Flow (Volumetric)|FLOW|METERS3_PER_SEC<br>PERCENT<br>SCFM<br>LITERS_PER_SEC<br>LITERS_PER_MIN<br>GALLONS_PER_SEC<br>GALLONS_PER_MIN|--|--
Flow (Mass)|FLOW_MASS|KILO_PER_SEC<br>LBS_PER_SEC|--|--
Force|FORCE|NEWTON|--|--
Frequency|FREQUENCY|HERTZ<br>KHZ<br>MHZ|--|--
Fuel efficiency|--|--|--|not supported
GPS / Location|LOCATION|LAT_LONG<br>LAT_LONG_ALT|--|JSON payload example:<br> <pre><code>{"lat": "{value}","lng":"{value}","alt":"{value}","acc":"{value}"}</code></pre>
Half-life|--|--|--|not supported
Heat|HEAT|--|--|not supported
Heat capacity|--|--|--|not supported
Heat flux density|--|--|--|not supported
Humidity|HUMIDITY|PERCENT|%|--
Illuminance|--|--|--|not supported
Impedance|IMPEDANCE|OHM<br>KILOOHM<br>MEGAOHM|--|--
Impulse|--|--|--|not supported
Inductance|--|--|--|not supported
Irradiance|--|--|--|not supported
Intensity|--|--|--|not supported
Jerk|JERK|METER_PER_SEC3|--|--
Jounce|--|--|--|not supported
Length|LENGTH|METERS<br>CENTIMETERS<br>KILOMETERS<br>MILLIMETERS<br>FEET<br>INCH<br>YARD<br>MILES<br>MICRONS|--|--
Linear density|--|--|--|not supported
Luminous Intensity|LUMINOUS_INTENSITY|CANDELA|--|--
Luminious flux|--|--|--|not supported
Magnetic field strength|--|--|--|not supported
Magnetic flux|--|--|--|not supported
Magnetic flux density|--|--|--|not supported
Magnetization|--|--|--|not supported
Mass|MASS|MILLIGRAM<br>GRAM<br>KILOGRAM<br>POUND<br>OZ<br>TON<br>METRIC_TON|--|--
Mass fraction|--|--|--|not supported
Mean lifetime|--|--|--|not supported
Molar concentration|--|--|--|not supported
Molar energy|--|--|--|not supported
Molar entropy|--|--|--|not supported
Molar heat capacity|--|--|--|not supported
Moment of inertia|--|--|--|not supported
Momentum|--|--|--|not supported
Percentage|PERCENTAGE|PERCENT|%|--
Permeability|--|--|--|not supported
Permittivity|--|--|--|not supported
Plane angle|ANGLE|RADIAN<br>DEGREE<br>ARCMINUTE<br>ARCSECOND|--|--
Power|POWER|WATT<br>MILLIWATT<br>KILOWATT<br>MEGAWATT|--|--
Pressure|PRESSURE|MBAR<br>BAR<br>PSI<br>TORR<br>PASCAL<br>ATMOSPHERE|--|--
Pop|--|--|--|not supported
Radioactive Activity|--|--|--|not supported
Radioactive Dose|--|--|--|not supported
Radiance|--|--|--|not supported
Radiant intensity|--|--|--|not supported
Reaction rate|--|--|--|not supported
Refraction rate|--|--|--|not supported
Refractive index|--|--|--|not supported
Solid angle|--|--|--|not supported
Speed|SPEED|METER_PER_SEC<br>MPH<br>KPH<br>IN_PER_SEC|--|--
Specific Energy|--|--|--|not supported
Specific heat capacity|--|--|--|not supported
Specific Volume|--|--|--|not supported
Spin|--|--|--|not supported
Strain|STRAIN|PERCENT|%|--
Stress|--|--|--|not supported
Surface tension|--|--|--|not supported
Temperature|TEMPERATURE|KELVIN<br>DEG_FAHRENHEIT<br>DEG_CELSIUS<br>RANKINE|--|--
Thermal conductivity|--|--|--|not supported
Time|TIME|SECONDS<br>MILLISECOND<br>MINUTE<br>HOUR<br>DAY<br>YEAR|--|--
Torque|TORQUE|NEWTON_METER<br>POUND_FOOT|--|--
Velocity|VELOCITY|METER_PER_SEC|--|--
Volume|VOLUME|METER3<br>FEET3<br>LITRE<br>GALLON<br>PINT<br>INCH3<br>CENTIMETER3|--|--
Wavelength|--|--|--|not supported
Wavenumber|--|--|--|not supported
Wavevector|--|--|--|not supported
Weight|WEIGHT|NEWTON<br>POUND|--|--
Work|--|--|--|not supported
