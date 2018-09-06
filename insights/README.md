# Insight Transform How-To Guide

## Basic Concepts

ExoSense™ Insights are a specific type of Signal Transformation that allow
customers to integrate in a flexible way with a wide array of external
streaming analytics services. They are:

### Streaming
* At their core, Insights are not stateful; similar to other
  Transformations like Join and Linear Gain, they operate on a single piece of
  Signal data.
* For a given Join on SignalA and SignalB, each time a piece of
  data comes in from _either_ of those Signals, the Join runs (and returns a
  joined value).
* The Join transform uses the last seen value of any Signal not
  present in the data sent to the Join at any given time.

### Exchange Elements
* From the ExoSense and Murano perspective, an Insight is an
  IoT Exchange Service that begins with the word "Insight".
* The Swagger definition for the Service is found in this repository:
  insight-template.yaml. Use [swagger.io](https://editor.swagger.io/) to view
  the incoming and outgoing data format.

### Webservers
* The Exchange Service created for an Insight defines the URL
  to be requested when ExoSense needs to do any of the following:
    * get high-level information about the Insight
    * get a list of available functions for a group, along with their
      required parameters
    * get info about a specific function, along with its required parameters
    * process incoming Signal data (i.e. "run the function")
* This URL can be hosted anywhere, including:
    * Murano
    * Amazon Web Services
    * Microsoft Azure
    * Google Cloud Products

### Services
* The code behind the Insight is entirely up to its creator; as long as it
  conforms to the Swagger definition, ExoSense will happily send and receive
  data from it.
* The code that makes up an Insight can be written in any language available
  within the chosen host.

## Enabling Within ExoSense
To enable an Insight within ExoSense:
1. Create an Asset and add Signals to that Asset.
1. Click the [+] button next to a Signal
1. Under "Type", select the Insight you created. The displayed name is the
  "name" value returned by a GET /info request.
1. Enter a valid Group ID (e.g. "80000001").
1. Select the desired Function (e.g. "Add Numbers").
1. Select a signal from the Input Signal 1 dropdown
1. Supply a number to add to the chosen Signal in the Parameters section
  (e.g. "adder")
1. Supply a name, type, and unit for the output signal.
1. Click save.

## Requirements

1. Customized Swagger file (template is insight-template.yaml). The only
  sections that should be modified are:
    * info
    * host
    * basePath (in many cases the host URL is sufficient and this should be
      left as "/")
1. URL to that Swagger file (e.g. by using Gist, and copying the URL from the
  "raw" view)
1. HTTP service with correct endpoints, as defined in the insight-template.yaml
  file.
    * `get /info`

      This endpoint is used to get high-level information about an Insight,
      including the name displayed within the ExoSense UI.

    * `get /insight/{fn}`

      This endpoint is used to get all the necessary information about a
      specific Function, including:
        * Description
        * Input Signals (inlets)
        * Output Signals (outlets)
        * User-Supplied Constants

    * `post /insights`

      This endpoint is used to supply a list of Functions (and their
      info/requirements/meta-data) available to a specific Group (supplied as a
      Group ID)

    * `post /process`

      This endpoint is used to process Signal data and return a new Signal
1. Exchange Service beginning with the word "Insight" and using the Swagger
  file URL.
1. Exchange Service added to your Business.
1. Exchange Service added to your ExoSense Instance.

## Examples

### Murano Example

#### Swagger File
Modify the info, host, and basePath sections of the Swagger template:
```yaml
swagger: "2.0"

info:
  version: "1.0"
  title: My Demo Insight
  description: |
    This demo Insight is a Functional Module that can be added to Murano Exchange
    and enabled within ExoSense.
  contact:
    name: Stephen Dedalus
    email: sdedalus@clongowes.edu

host: mydemoinsight.apps.exosite.io # Set this to the host your function is on
basePath: / # Set this or the path according to your function

[...]
```

#### Public URL
Upload via [GitHub Gist](https://gist.github.com/) 
or use [defunkt/gist](https://github.com/defunkt/gist)

#### HTTP Service
1. Create a Murano Application with a reasonable name (e.g. mydemoinsight)
1. Using either Murano in a browser or with
  [MuranoCLI](http://docs.exosite.com/development/tools/murano-cli/),
  create the following API endpoints with the code in examples/murano/routes:
    * `GET /info`
    * `GET /insight/{fn}`
    * `POST /insights`
    * `POST /process`
1. Create the following Module with the code in examples/murano/modules
    * `insightModule`

#### Exchange Service
* In Murano, go to IoT Marketplace and click on Publish on the left
* Parameters:
  * Element name: *must* begin with "Insight" (e.g. "Insight Demo 01")
  * Element type: Service
  * Configuration File URL: the URL from your Gist (make sure to copy the URL
    from the "raw" view)
  * ... (fill the rest out as you see fit)

#### Add Insight To Business
Go to the Element you created in IoT Marketplace and add it to your Murano Business.

#### Add Insight To ExoSense
Go to the ExoSense instance Solution in Murano, and click the orange "Enable
Services" button at the top right. Find the Service you just created and enable
it. Your Insight is now available to use in ExoSense! Now, all you need to do is
[create an Insight Transormation in the ExoSense UI](#enabling-within-exosense).
