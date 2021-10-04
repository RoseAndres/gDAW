# **gDAW**
A Godot Plugin for generating sound in real-time.

## **Description**
gDAW is a tidy little plugin that adds its own custom nodes that allow users to generate audio in real-time using [Waveforms](https://en.wikipedia.org/wiki/Waveform) and [ADSR Envelopes](https://en.wikipedia.org/wiki/Envelope_(music)). These custom nodes have many settings that can be used to adjust the sound created.

## **Installation**
Follow the standard Godot instructions for [downloading and enabling a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin).
gDAW can be found [here](*coming soon*) in the Godot Asset Library.

## **Configuration**
gDAW's custom nodes depend on a couple of global variables that must be autoloaded. These values can be tailored specific to your project, but the defaults should fit just fine for most use cases.

#### **Follow the steps below to configure gDAW:**
1\. Create a new script named `gdaw_config.gd` and copy/paste the script provided below (this script is also available at `/gdaw/gdaw_config.gd` within this repo).
```
tool
extends Node

# required by gDAW for custom nodes to function
var max_db: float = -6.0
var min_db: float = -80.0
var sample_rate = 32000
```
#### **Global Vars**
- `max_db`: The maximum volume (in decibels) any custom nodes provided by gDAW can reach
- `min_db`: The minimum volume (in decibels) any custom nodes provided by gDAW can reach
- `sample_rate`: This is the waveform sample rate that gDAW uses to create sound. Values between `22050` and `32000` are recommended. A higher value will result in a cleaner, smoother sound, while introducing an increasing amount of audio lag, as it requires more CPU to create the audio. The lower the value goes, the more scratchy and static-y the sound will get, due to the "resolution" of the sound being lower.

2\. Create a new [AutoLoad](https://docs.godotengine.org/en/stable/getting_started/step_by_step/singletons_autoload.html#autoload) in the Project Settings for your project. Give it the name "GDawConfig" (this must match exactly) and make sure that the path is pointing at the script you created in the last step.

3\. That's it! You're ready to start making some noise!

## **Documentation**
See the [Wiki](https://github.com/RoseAndres/gDAW/wiki) to view documentation on the custom nodes added by gDAW.

## **Similar Projects**
If you are looking for a fully-fledged DAW built with Godot, you may be interested in [GoDAW](https://github.com/QuadCubedStudios/GoDAW).

## **Roadmap**
Here is a short list of things I'd like to add to the plugin when I've got some time:
1. An in-editor gui for manipulating the ADSR envelope, like most modern DAW software has
2. A custom Envelope node that would allow users to apply ADSR envelopes to ANY value on ANY node (this may actually be better as its own independent plugin, since it wouldn't necessarily be related to generating real-time sounds).
3. A custom LFO node
4. A Chord node for easily playing multiple waveforms at the same time


## **Contributing**
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## **License**
[GNU LGPLv3](https://choosealicense.com/licenses/lgpl-3.0/).\
For proprietary use, please contact me about purchasing a license.
