## Frequently Asked Questions:
***

**What version of Project Zomboid is this for?**  
Build **41.65+** (as of 12/31/2021)
***

**Does this work for multiplayer?**  
Yes.
***

**Does this mod work with non-vanilla maps?**  
Yes. Any map, any size.
***

**Does this work with on-going/old saves?**  
Applying the mod to an ongoing save will use default settings for events. By default, events will taper off becoming less frequent up to the end of the duration setting. For more options see the sandbox settings.
***

**Do I need to disable the vanilla helicopter?**  
The mod will force the vanilla event to not appear. It can still be launched with '/chopper' if you wish. If it does appear without prompt please let us know.
***

**I'm hosting a multiplayer server, how do I configure EHE for my game?**  
Whether you're playing a co-op, local dedicated or rented server, at this point in time you need to manually add the sandbox options for EHE to your save.

1. Navigate to "C:\Users%username%\Zomboid\Server". Open the "config_SandboxVars.lua" with the text editor of your choice, and scroll to the bottom of the document.

2. Add the mod's sandbox options to your existing settings. _Double check to make sure it doesn't already exist!_

**Default Sandbox Config**  
```lua
ExpandedHeli = {
        SchedulerDuration = 90,
        StartDay = 1,
        ContinueScheduling = false,
        ContinueSchedulingLateGameOnly = true,
        -- Frequencies: 1="Never", 2="Rare", 3="Uncommon", 4="Common", 5="Frequent", 6="Insane"
        Frequency_jet = 3,
        Frequency_police = 3,
        Frequency_news_chopper = 3,
        Frequency_military = 3,
        Frequency_FEMA_drop = 3,
        Frequency_samaritan_drop = 3,
        Frequency_survivor_heli = 3,
        Frequency_raiders = 3,
    },
```

**Additional config options for the [Super Weird](https://steamcommunity.com/sharedfiles/filedetails/?id=2580001162) sub-mod:**  
_These go inside of the { } above._
```lua
        Frequency_IRS = 3,
        Frequency_Spiffocopter = 3,
        Frequency_TISCreamery = 3,
        Frequency_UFO = 3,
```

**Frequencies:** _Also included in the above config example as a comment._
```lua
	1 = "Never"
	2 = "Rare"
	3 = "Uncommon"
	4 = "Common"
	5 = "Frequent"
	6 = "Insane"
```
_Ensure that your formatting is correct, the document should end with a "}"._
***

**What are the custom sandbox options? What do they mean?**

**Start Day**  
Pretty self explanatory, it is when the scheduler will engage. Certain events have "start day factors" in their presets which is calculated off the scheduler duration.

**Scheduler's Duration**  
How many days after the start day will the scheduler run for.

**Frequency**  
Assigned to each event, and controls how likely it is the scheduler will assign these events.

**Continue Scheduler / Continue Scheduler Late-Game Only**  
The events in the scheduler change depending on how far along in the scheduler's duration you are. "Continue Scheduling" being toggled on means events continue to appear in their 'final stages' forever- this means different things for different events. Some events also have their own cut off period based on their preset. In order for these events to continue to appear you need to toggle off _Continue Scheduling Late-Game Only_.

**Can I spawn events as an admin?**  
Yes, if you launch the game with `-debug` in launch options, you can find debug tests for events in the menu. This is a temporary approach before something more concrete comes out. You can also use the Twitch-Integration sub-mod to launch events. In both cases you cannot control whom the events target.