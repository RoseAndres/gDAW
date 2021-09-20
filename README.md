# GoDAW
A Godot Plugin for generating sound in real-time.

## Description
GoDAW is a tidy little plugin that adds its own custom nodes that allow users to generate audio in real-time using [Waveforms](https://en.wikipedia.org/wiki/Waveform) and [ADSR Envelopes](https://en.wikipedia.org/wiki/Envelope_(music)). These custom nodes have many settings that can be used to adjust the sound created; see the [Usage](#usage) section for more info.

## Getting Started
To get started with GoDAW, you can either watch the [Getting Started Video](*coming soon*), or continue reading the ReadMe for a text-based walkthrough.

## Installation
Follow the standard Godot instructions for [downloading and enabling a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin).
GoDAW can be found [here](*coming soon*) in the Godot Asset Library.

## Configuration
GoDAW's custom nodes depend on a couple of global variables that must be autoloaded. These values can be tailored specific to your project, but the defaults should fit just fine for most use cases.

### Follow the steps below to configure GoDAW:
1\. Create a new script named `godaw_config.gd` and copy/paste the script provided below (this script is also available at `/godaw/godaw_config.gd` within this repo).
```
tool
extends Node

# required by GoDAW for custom nodes to function
var godaw_max_db: float = -6.0
var godaw_min_db: float = -80.0
var godaw_sample_rate = 32000
```
#### Global Vars
- `godaw_max_db`: The maximum volume (in decibels) any custom nodes provided by GoDAW can reach
- `godaw_min_db`: The minimum volume (in decibels) any custom nodes provided by GoDAW can reach
- `godaw_sample_rate`: This is the waveform sample rate that GoDAW uses to create sound. Values between `22050` and `32000` are recommended. A higher value will result in a cleaner, smoother sound, while introducing an increasing amount of audio lag, as it requires more CPU to create the audio. The lower the value goes, the more scratchy and static-y the sound will get, due to the "resolution" of the sound being lower.

2\. Create a new [AutoLoad](https://docs.godotengine.org/en/stable/getting_started/step_by_step/singletons_autoload.html#autoload) in the Project Settings for your project. Give it the name "GodawConfig" (this must match exactly) and make sure that the path is pointing at the script you created in the last step.

3\. That's it! You're ready to start making some noise!

## Usage


## Roadmap
Here is a short list of things I'd love to add to the plugin when I've got some spare time:
1. An in-editor gui for manipulating the ADSR envelope, like most modern DAW software has.
1. A custom Envelope node that would allow users to apply ADSR envelopes to ANY value on ANY node (this may actually be better as its own independent plugin, since it wouldn't necessarily be related to generating real-time sounds).
2. A custom LFO node


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GNU LGPLv3](https://choosealicense.com/licenses/lgpl-3.0/).\
For proprietary use, please contact me about purchasing a license.
