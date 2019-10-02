---
description: >-
  This site is for documentation of data and interface schema, used for
  reference by developers.
---

# Overview

## ExoSense™️ Industrial IoT Schemas

This repository provides specification documents for the ExoSense™️ application and related technologies as a part of Exosite's Industrial IoT product offering. These documents are meant as reference details for those groups of people including OEMs building connected devices / gateways to work with ExoSense, OEMs and integrators creating custom insight transforms / rules / integrations, and for Exosite's developers building and improving ExoSense.

_Note: These specifications are not meant to be developer guides but instead provide schemas and reference material that allow for standardization. For those looking for developer guide information, this can be found on Exosite's_ [_ExoSense documentation site_](https://exosense.readme.io/)_._

## Schemas

| Schema |
| :--- |
| [ExoSense™️ Channel and Signal Interface](exosense-data-schema/exosense-tm-channel-and-signal-data-schema.md) |
| [Channel & Signal Data Types](exosense-data-schema/exosense-tm-channel-and-signal-data-types.md) |
| ExoSense™️ Insight Integration |
| Device Management OTA Package Update |

## Definitions

The reader of this documentation should have a grasp on the following items or will need to for this document to make sense.

| Term | Description | More Information |
| :--- | :--- | :--- |
| ExoSense™️ | Industrial IoT Application solution created and offered by [Exosite](https://app.gitbook.com/@exositedocs/s/exosite-iiot-data-schema/definitions/~/settings/exosite.com)​ | ​ |
| Device/Gateway | An electronic device with an IP Connection sending data to a platform. In this case is interacing with directly connected sensors, custom protocol connected sensors, or fieldbus connected equipment | ​ |
| Sensors | Physical sensors connected to a Device/Gateway via wired or wireless protocol or IO \(onboard\). Sensors are typically specific to a unit of measure - e.g. temperature, pressure, etc. | ​ |
| Channel | An ExoSense concept to identify an **individual stream** of information sent to ExoSense by an **unique device** that is specific to a type and with a specific unit of measure from that local physical environment \(e.g. Temperature or Valve 1 status\). Can also be information such as memory on the device, status information, etc. | Typically a device is sending many channels of data for all of the sensors that are connected. |
| Signal | An ExoSense concept similiar to channel but is the part of a virtual Asset object that describes and stores the data. Signals can be transformed, exported, visualzied, and have rules ran on them. The source for a signal is typically a device channel but doesn't have to be. The signal essentially subscribes to it's source. | ​ |
| Asset | An ExoSense concept for digitizing an Asset \(a machine, system, equipment, etc\) | ​ |
| Fieldbus | Industrial protocols like Modbus TCP or RTU, J1939, CANOpen, etc that allow machines, controls, equipment to have a standard way to talk to each other. | ​ |

### Versioning / Contributing

This repository is managed by Exosite. [How contributions are managed are detailed here](contributing.md).

