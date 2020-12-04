# Turn rate

## How to use it?

* Load telemetry data into Tacview.

* From the Add-Ons menu, select Turn Rate -> Instantaneous or Sustained or both. 

## Output

Maximum attained turn rate, in degrees per second, at a given altitude and speed.

High values are flagged in green and low values are flagged in orange.

## Parameters

Values over the 80th percentile are flagged in green and values under the 20th percentile are flagged in orange. 

Instantaneous turn rate is calculated over a period of 1 second and sustained turn rate is calculated over a period of 5 seconds.

If there was a change of altitude of over 20m in the case of instantaneous turn rate, or 200m in the case of sustained turn rate, the turn rate is ignored. 

If turn rate is less than 5, it is ignored.

Feel free to change these constants in the code:

* FlagHighPercentile
* FlagLowPercentile
* InstantaneousTurnRatePeriod
* SustainedTurnRatePeriod
* MaxChangeInAltitudeInstantaneousMeters
* MaxChangeInAltitudeSustainedMeters
* MinimumTurnRate