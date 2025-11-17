# Batch Processing

This add-on recursively loads a folder of .acmi files and peforms an action on each one.
This could be helpful for anyone looking for statistics.
In this example, it counts how many of each type of fixed wing aircraft or rotorcraft appear in total.
A table is built and printed to a .csv file.
Modify the add-on to perform whatever calculations you are interested in!

## How to use it?

* Store all the .acmi files you want to analyze in a single folder, with subfolders if desired.
* Run the command *Batch Process Files* from Tacview's Add-Ons menu.
* Select the folder which contains your .acmi files.
* Choose in which file you want to save the compiled statistics.

Wait for the addon to process the data - If you don’t get any error message, the csv file should now be ready.

## Output

A csv file is created, consisting of a count of each type of aircraft found in all the .acmi files.

## Limitations

Anyone who wishes to use this add-on to analyze files will need to significantly modify it to output the actual desired statistics.