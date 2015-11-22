## DNMKIT

[![Build Status](https://travis-ci.org/jsbean/DNMKit.svg)](https://travis-ci.org/jsbean/DNMKit)

Work-in-progress.

iPad based music notation renderer.


#### Create a file

Use filename extension: ```.dnm``` 

Save anywhere in project (to be retrieved from ```NSBundle.mainBundle()```)

### Text Input Format

**Declare Performers** (humans doing things) with:    
- ```Performer identifier``` (string, I've been using two uppercase letters)
- ```1...n``` pairs of ```Instrument identifiers``` and ```InstrumentTypes```
    - ```Instrument identifier``` (string, I've been using two lowercase letters)


Note: these ```InstrumentTypes``` must strictly conform to the list of possible ```InstrumentTypes```. This list is coming shortly. Temporary list can be seen [here](https://github.com/jsbean/DNMKit/issues/18). 


**Example**:

Add a performer and their instruments: (Violinisit who is just playing Violin)

```Swift
P: VN vn Violin
```

Add another: (Cellist who is just playing Violoncello)

```Swift
P: VN vn Violin
P: VC vc Violoncello
```

Add another instrument to a performer's arsenal, perhaps a foot-pedal: 

```Swift
P: VN vn Violin
P: VC vc Violoncello cc ContinuousController
```

#### Start a piece

```#``` Add a Measure (you don't need to know the length, it gets calculated based on whats inside)

**Declare where to put a new event**
- ```|``` Start new rhythm on beat of current measure (optional if first rhythm of measure)
- ```+``` Start new rhythm after the last rhythm
- ```-``` Start new rhythm at the onset of the last rhythm (not supported yet, not tested)

**Start a rhythmic event**

```b: Int s: Int``` Create a rhythmic container with the duration of Beats (```b```) and Subdivision value (```s```). (currently, only powers-of-two are allowed (```4, 8, 16, 32, 64, 128, etc...```))


#### Projects

* **DNMMODEL**: iOS / OSX framework that includes:
    * Model of music
    * Parser for DNMShorthand
    * [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for JSON i/o
    

* **DNM_iOS**: iOS application for graphical representation of music

* **DNM Text Editor**: Simple text editor with text highlighting specific to DNMShorthand

