<?php

// PHPTacview
// Copyright (c) 2006 Julien "Ezor" RozÃ©

// History:

// 2021-07-28 (Updated by BuzyBee)
// * ADDED aircraft identification photos for new aircraft
// * ADDED Occurrences of multiple projectiles fired at the same time. 
// * ADDED tag HasTakenOff (prev. called HasTakeOff)
// * ADDED stat - kills of trucks
// * IMPROVED readability (color scheme, spacing)
// * FIXED Many warnings about bad array indexes

// 2015-03-23 (Updated by Vyrtuoz)
// * ADDED Missing labels from English and French translations
// * FIXED Many warnings about bad array indexes
// * Optimized JPEG pictures (without loss)
// * Minor source code cleanup

// 2015-02-26 (Updated by Khamsin)
// * MODIFY arrays cause new XML

// 2011-08-01 (Updated by Aikanaro)
// * ADDED Italian localization
// * ADDED Group Field
// * ADDED Group in Event
// * MODIFIED css file colour
// * ADDED Destroyed in pilot stats
// * FIXED bug count display destroyed in pilot stats by Aikanaro
// * MODIFIED & ADDED icon IMAGES Bomb, Parachutist, Chaff, Flare, Hit
// * ADDED images in objectIcons
// * MODIFIED debriefing.php
// * FIXED bug display multy file .xml in debriefing.php
// * FIXED bug display Kill in pilots stats

// 2011-04-09 (Updated by Vyrtuoz)
// * ADDED Support for XML Debriefings v0.93
// * ADDED English localization
// * FIXED Localization files are now all in UTF-8
// * FIXED Player pictures paths
// * FIXED Several PHP warnings (not all of them)

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
class tacview
{
    var $language = array();
    var $htmlOutput = "";

    // Oggetto Airport
    var $airport = array();
    var $tagAirportOpened = false;
    var $airportCurrentId = 0;

    // Oggetto Primary
    var $primaryObjects = array();
    var $tagPrimaryObjectOpened = false;
    var $primaryObjectCurrentId = 0;

    // Oggetto Secondary
    var $secondaryObjects = array();
    var $tagSecondaryObjectOpened = false;
    var $secondaryObjectCurrentId = 0;

    // Oggetto Parent
    var $parentObjects = array();
    var $tagParentObjectOpened = false;
    var $parentObjectCurrentId = 0;

    // vettore oggetti -- non usato --
    var $objects = array();
    var $tagObjectOpened = false;
    var $objectCurrentId = 0;

    // vettore eventi
    var $events = array();
    var $tagEventOpened = false;
    var $eventCurrentId = 0;
    var $stats = array();
    var $missionName = "";
    var $xmlParser = 0;
    var $currentData = "";
    var $tagObjectsOpened = false;
    var $tagEventsOpened = false;
    var $tagOpened = "";
    var $startTime;
    var $duration;
    var $image_path = "";
    var $firephp;
    // we log today’s date as an example. you could log whatever variable you want to

    //
    // constructor
    //
    function tacview($aLanguage = "it")
    {

        // Open language file
        require_once "languages/tacview_" . $aLanguage . ".php";
        $this->language = $_LANGUAGE;
    }

    //
    // return language caption
    //
    function L($aId)
    {
        return $this->language[$aId];
    }

    //
    // add HTML to the current output
    //
    function addOutput($aHtml)
    {
        $this->htmlOutput .= $aHtml;
    }

    //
    // return output html
    //
    function getOutput()
    {
        return $this->htmlOutput;
    }

    //
    // return a formated timestamp
    //
    function displayTime($aTime)
    {
        $lTime        = $aTime;
        $lHour        = floor($lTime / 3600);
        $lHourDisplay = floor($lHour - (floor($lHour / 24) * 24));
        $lMinute      = floor(($lTime - ($lHour * 3600)) / 60);
        $lSecond      = floor($lTime - ($lHour * 3600) - $lMinute * 60);

        if ($lMinute == "")
		{
            $lMinute = "00";
        }
		else
		{
            if ($lMinute < 10)
			{
                $lMinute = "0" . $lMinute;
            }
        }

        if ($lSecond < 10)
		{
            $lSecond = "0" . $lSecond;
        }

        if ($lHourDisplay < 10)
		{
            $lHourDisplay = "0" . $lHourDisplay;
        }

        $lHTML = $lHourDisplay . ":" . $lMinute . ":" . $lSecond;

        return $lHTML;
    }

    //
    // Increase statistic (safe)
    //
    function increaseStat(&$Array, $Key0, $Key1 = null)
    {
        if (isset($Key1))
		{

            if (!array_key_exists($Key0, $Array))
			{
                $Array[$Key0] = array();
            }

            if (!array_key_exists($Key1, $Array[$Key0]))
			{
                $Array[$Key0][$Key1] = 1;
            }
			else
			{
                $Array[$Key0][$Key1]++;
            }
        } else {

            if (!array_key_exists($Key0, $Array))
			{
                $Array[$Key0] = 1;
            }
			else
			{
                $Array[$Key0]++;
            }
        }
    }

    //
    // Retrieve stats count (safe)
    //
    function getStat($Array, $Key0, $Key1 = null)
    {

        if (isset($Array) && array_key_exists($Key0, $Array))
		{
            if (!isset($Key1))
			{
                return $Array[$Key0]['Count'];
            }

            if (array_key_exists($Key1, $Array[$Key0]))
			{
                return $Array[$Key0][$Key1]['Count'];
            }
        }

        return null;
    }

    //
    // proceed stats of the xml file
    //
    function proceedStats($aFile, $aMissionName)
    {
        $this->htmlOutput  = "";
        $this->objects     = array();
        $this->events      = array();
        $this->stats       = array();
        $this->sam_enemies = array(); // Aggiunto da 53.Sparrow per contsentire le statistiche sugli abbattimenti A/G ed elicotteri

        // parse XML file to get events and objects

        $this->parseXML($aFile);

        // echo '============================================================================';
        // echo '<pre>'; print_r($this->events); echo '</pre>';
        // echo '============================================================================';

        if ($this->missionName == "")
		{
            $this->missionName = $aMissionName;
        }

        // some scripts

        $this->addOutput('<script type="text/javascript">');
        $this->addOutput('function showDetails(zoneAffiche){');
        $this->addOutput('	if(document.getElementById(zoneAffiche).style.display==""){');
        $this->addOutput('		document.getElementById(zoneAffiche).style.display="none";');
        $this->addOutput('	}else{');
        $this->addOutput('		document.getElementById(zoneAffiche).style.display="";');
        $this->addOutput('	}');
        $this->addOutput('}');
        $this->addOutput('</script>');

		// ***********************************************************
		// PRESENTATION TABLE - Mission Name, Time, Duration
		// ***********************************************************

        $this->addOutput('<h1>' . $this->L('information') . '</h1>');
        $this->addOutput('<table class="presentationTable">');
        $this->addOutput('<tr class="presentationTable">');
        $this->addOutput('<td class="presentationTable">' . $this->L('missionName') . ':</td>');
        $this->addOutput('<td class="presentationTable">' . $this->missionName . '</td>');
        $this->addOutput('</tr >');
        $this->addOutput('<tr class="presentationTable">');
        $this->addOutput('<td class="presentationTable">' . $this->L('missionTime') . ':</td>');
        $this->addOutput('<td class="presentationTable">' . $this->displayTime($this->startTime) . '</td>');
        $this->addOutput('</tr>');
        $this->addOutput('<tr class="presentationTable">');
        $this->addOutput('<td class="presentationTable">' . $this->L('missionDuration') . ':</td>');
        $this->addOutput('<td class="presentationTable">' . $this->displayTime($this->duration) . '</td>');
        $this->addOutput('</tr>');
        $this->addOutput('</table>');

		// ***********************************************************
		// Iterate through events
		// ***********************************************************

        foreach ($this->events as $key => $event)
		{
            // List pilots of Aircraft and Helicopters

            if ($event["PrimaryObject"]["Type"] == "Aircraft" or $event["PrimaryObject"]["Type"] == "Helicopter") 
			{
				if(array_key_exists("Pilot",$event["PrimaryObject"]))
				{
	                $primaryObjectPilot = $event["PrimaryObject"]["Pilot"];
					// crea il ramo per ogni Pilota (di aereo o di elicottero)
					$this->stats[$primaryObjectPilot]["Aircraft"] = $event["PrimaryObject"]["Name"];
				}
				else
				{
					continue;
				}

				if(array_key_exists("Group",$event["PrimaryObject"]))
				{
					$this->stats[$primaryObjectPilot]["Group"] = $event["PrimaryObject"]["Group"]; // ADDED field Group by Aikanaro
				}

                if (!array_key_exists("Events", $this->stats[$primaryObjectPilot]))
				{
                    $this->stats[$primaryObjectPilot]["Events"] = array();
                }

				array_push($this->stats[$primaryObjectPilot]["Events"], $event);

				// fine creazione ramo

                switch ($event["Action"])
				{
					case "HasLanded":

						$this->increaseStat($this->stats[$primaryObjectPilot], "Lands", "Count");

						if (!isset($event["Airport"]))
						{
                            $this->increaseStat($this->stats[$primaryObjectPilot]["Lands"], "No Airport");
                        }
						else
						{
                            $this->increaseStat($this->stats[$primaryObjectPilot]["Lands"], $event["Airport"]["Name"]);
                        }

                        break;

					case "HasTakeOff":	// obsolete
                    case "HasTakenOff":

						$this->increaseStat($this->stats[$primaryObjectPilot], "TakeOffs", "Count");

						if (!isset($event["Airport"]))
						{
                            $this->increaseStat($this->stats[$primaryObjectPilot]["TakeOffs"], "No Airport");
                        }
						else
						{
                            $this->increaseStat($this->stats[$primaryObjectPilot]["TakeOffs"], $event["Airport"]["Name"]);
                        }

                        break;

                    case "HasFired":

						$this->increaseStat($this->stats[$primaryObjectPilot], "Fired", "Count");
						$this->increaseStat($this->stats[$primaryObjectPilot], "Fired", $event["SecondaryObject"]["Name"]);

                        break;

                    case "HasBeenDestroyed":

                        $this->increaseStat($this->stats[$primaryObjectPilot], "Destroyed", "Count");

                        break;

                    case "HasBeenHitBy":

                        $this->increaseStat($this->stats[$primaryObjectPilot], "Hit", "Count");
						$this->increaseStat($this->stats[$primaryObjectPilot], "Hit", $event["SecondaryObject"]["Name"]);

                        if (	array_key_exists("ParentObject",$event) and
								array_key_exists("Pilot", $event["ParentObject"]) and
								$event["ParentObject"]["Pilot"] != "" and
								substr($event["ParentObject"]["Pilot"], 0, 6) != "Pilot")
						{

                            $parentObjectPilot = $event["ParentObject"]["Pilot"];

                            // Friendly Fire

                            if ($event["ParentObject"]["Coalition"] == $event["PrimaryObject"]["Coalition"])
							{
                                $this->increaseStat($this->stats[$parentObjectPilot], "FriendlyFire", "Count");
								$this->increaseStat($this->stats[$parentObjectPilot], "FriendlyFire", $event["PrimaryObject"]["Name"]);
                            }
							elseif (!isset($this->stats[$parentObjectPilot]))
							{
                                // pilota non ancora inserito -> viene creato il ramo

                                $this->stats[$parentObjectPilot]["Aircraft"] = $event["ParentObject"]["Name"];
                                $this->stats[$parentObjectPilot]["Group"]    = $event["ParentObject"]["Group"];

                                if (!array_key_exists("Events", $this->stats[$parentObjectPilot]))
								{
                                    $this->stats[$parentObjectPilot]["Events"] = array();
                                }

                                array_push($this->stats[$parentObjectPilot]["Events"], $event);

                                // fine creazione ramo

                            }

                            if (!array_key_exists("Killed", $this->stats[$parentObjectPilot]))
							{
								$this->stats[$parentObjectPilot]["Killed"] = array();
                            }

                            $this->increaseStat($this->stats[$parentObjectPilot]["Killed"], $event["PrimaryObject"]["Type"], "Count"); // Fix bug display Kill change from SecondaryObject to ParentObject
							$this->increaseStat($this->stats[$parentObjectPilot]["Killed"], $event["PrimaryObject"]["Type"], $event["SecondaryObject"]["Name"]); // Fix bug display Kill change from SecondaryObject to ParentObject*/

						}
                        break;

				}
			}
			elseif ($event["PrimaryObject"]["Type"] == "Tank" or
					$event["PrimaryObject"]["Type"] == "SAM/AAA" or
					$event["PrimaryObject"]["Type"] == "Ship" or 
					$event["PrimaryObject"]["Type"] == "Car" )

					// Aggiunto da 36.Sparrow per consentire le statistiche sugli abbattimenti A/G ed elicotteri
				{
					switch ($event["Action"])
					{
						case "HasBeenHitBy":

							if (	array_key_exists("ParentObject",$event) and
									array_key_exists("Pilot", $event["ParentObject"]) and
									$event["ParentObject"]["Pilot"] != "" and
									substr($event["ParentObject"]["Pilot"], 0, 6) != "Pilot")
							{
									$parentObjectPilot = $event["ParentObject"]["Pilot"];

									if (!isset($this->stats[$parentObjectPilot]))
									{
										// If Pilot of Parent Object does not exist yet, create them.

										$this->stats[$parentObjectPilot]["Aircraft"] = $event["ParentObject"]["Name"];
										$this->stats[$parentObjectPilot]["Group"]    = $event["ParentObject"]["Group"];

										if (!array_key_exists("Events", $this->stats[$parentObjectPilot]))
										{
											$this->stats[$parentObjectPilot]["Events"] = array();
										}
									}

									array_push($this->stats[$parentObjectPilot]["Events"], $event);

							}
							else
							{
								continue;
							}

							// Was it Friendly Fire?

							if ($event["ParentObject"]["Coalition"] == $event["PrimaryObject"]["Coalition"])
							{
								  $this->increaseStat($this->stats[$parentObjectPilot], "FriendlyFire", "Count");
								  $this->increaseStat($this->stats[$parentObjectPilot], "FriendlyFire", $event["PrimaryObject"]["Name"]);
							}

							/*if (!array_key_exists("Killed", $this->stats[$parentObjectPilot]))
							{
							   $this->stats[$parentObjectPilot]["Killed"] = array();
							}

							$this->increaseStat($this->stats[$parentObjectPilot]["Killed"], $event["PrimaryObject"]["Type"], "Count");
							$this->increaseStat($this->stats[$parentObjectPilot]["Killed"], $event["PrimaryObject"]["Type"], $event["SecondaryObject"]["Name"]); */


							//echo "************************<br>";
							//echo $event ["SecondaryObject"] ["Pilot"]."<br>";
							//echo $event ["Time"]."--".$event ["PrimaryObject"]["Type"]."<br>";
							//echo "************************<br>";

						break;

						case "HasBeenDestroyed":

							if (	array_key_exists("SecondaryObject",$event) and
									array_key_exists("Pilot", $event["SecondaryObject"]) and
									$event["SecondaryObject"]["Pilot"] != "" and
									substr($event["SecondaryObject"]["Pilot"], 0, 6) != "Pilot")
							{
								$secondaryObjectPilot = $event["SecondaryObject"]["Pilot"];

								if (!isset($this->stats[$secondaryObjectPilot]))
								{
									// If Pilot of Secondary Object does not exist yet, create them.

									$this->stats[$secondaryObjectPilot]["Aircraft"] = $event["SecondaryObject"]["Name"];
									$this->stats[$secondaryObjectPilot]["Group"]    = $event["SecondaryObject"]["Group"];

									if (!array_key_exists("Events", $this->stats[$secondaryObjectPilot]))
									{
										$this->stats[$secondaryObjectPilot]["Events"] = array();
									}
								}

								array_push($this->stats[$secondaryObjectPilot]["Events"], $event);

							}
							else
							{
								continue;
							}

							// Was it Friendly Fire?

							if ($event["SecondaryObject"]["Coalition"] == $event["PrimaryObject"]["Coalition"])
							{
								  $this->increaseStat($this->stats[$secondaryObjectPilot], "FriendlyFire", "Count");
								  $this->increaseStat($this->stats[$secondaryObjectPilot], "FriendlyFire", $event["PrimaryObject"]["Name"]);
							}

							if (!array_key_exists("Killed", $this->stats[$event["SecondaryObject"]["Pilot"]]))
							{
								$this->stats[$event["SecondaryObject"]["Pilot"]]["Killed"] = array();
							}

							$this->increaseStat($this->stats[$secondaryObjectPilot]["Killed"], $event["PrimaryObject"]["Type"], "Count");
							$this->increaseStat($this->stats[$secondaryObjectPilot]["Killed"], $event["PrimaryObject"]["Type"], $event["PrimaryObject"]["Name"]);

						break;
					}

                //echo '============================================================================';
                //echo '<pre>'; print_r($event ["PrimaryObject"] ["Name"]); echo " - action:".$event ["Action"]; echo '</pre>';
                //echo '============================================================================';
                //echo '<pre>'; print_r($this->stats [$this->sam_enemies [$event ["PrimaryObject"] ["Name"]]] ); echo '</pre>';
                //echo '****************************************************************************';

				}
		}


		// ***********************************************************
		// STATISTICS TABLE - Display Stats per pilot
		// ***********************************************************

        $this->addOutput('<h1>' . $this->L('statsByPilot') . '</h1>');
        $this->addOutput('<table class="statisticsTable">');
        $this->addOutput('<tr class="statisticsTable">');
        $this->addOutput('<th class="statisticsTable">' . $this->L('pilotName') . '</th>');
    //  $this->addOutput('<th class="statisticsTable">' . $this->L('model') . '</th>');
        $this->addOutput('<th colspan="2" class="statisticsTable">' . $this->L('aircraft') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('group') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('takeoff') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('landing') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('firedArmement') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('killedAircraft') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('killedHelo') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('killedShip') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('killedSAM') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('killedTank') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('killedCar') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('teamKill') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('hit') . '</th>');
        $this->addOutput('<th class="statisticsTable">' . $this->L('destroyed') . '</th>');
        $this->addOutput('</tr>');

        //$class = "row1";

        foreach ($this->stats as $key => $stat)
		{

            if ($key != "" and substr($key, 0, 5) != "Pilot")
			{
                // $this->displayEventRow($event);
                $this->addOutput('<tr class="statisticsTable">');
                $this->addOutput('<td class="statisticsTable"><a href="javascript: showDetails(\'' . $key . '\')">' . $key . '</a></td>');
                $this->addOutput('<td class="statisticsTable"><img class="statisticsTable" src="objectIcons/' . str_replace(array(" ","/"), array("_","_"), $stat["Aircraft"]) . '.jpg" alt=""/></td>');
                $this->addOutput('<td class="statisticsTable">' . $stat["Aircraft"] . '</td>');

				if(array_key_exists("Group",$stat))
				{
					$this->addOutput('<td class="statisticsTable">' . $stat["Group"] . '</td>');
				}
				else
				{
					$this->addOutput('<td class=statisticsTable></td>');
				}

                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "TakeOffs") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Lands") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Fired") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Killed", "Aircraft") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Killed", "Helicopter") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Killed", "Ship") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Killed", "SAM/AAA") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Killed", "Tank") . '</td>');
				$this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Killed", "Car") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "FriendlyFire") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Hit") . '</td>');
                $this->addOutput('<td class="statisticsTable">' . $this->getStat($stat, "Destroyed") . '</td>');
                $this->addOutput('</tr>');

			// ***********************************************************
			// HIDDEN ROW & TABLE - Drill Down Per Pilot
			// ***********************************************************

                $this->addOutput('<tr id="'.$key.'" class="hiddenRow" style="display: none;">');
                $this->addOutput('<td class="hiddenRow" colspan="16">');
                $this->addOutput('<h2>' . $key . '</h2>');

				$this->addOutput('<table class="hiddenStatsTable">');

                // FIRST ROW - Aircraft icon

                $this->addOutput('<tr class="hiddenStatsTable">');
                
				$this->addOutput('<td class="hiddenStatsTable" colspan="3">');

                $this->addOutput('<h2>' . $this->L("aircraft") . '</h2>');

				if (isset($stat["Aircraft"]))
                    $x_air = $stat["Aircraft"];
                else
                    $x_air = "";

                $this->addOutput('<img class="hiddenStatsTable" src="./objectIcons/' . str_replace(array(" ","/"), array("_","_"), $x_air) . '.jpg" alt="" />');

                $this->addOutput('<h2>' . $this->L("pilotStats") . '</h2>');

                $this->addOutput('</td>');
                $this->addOutput('</tr>');

				// SECOND ROW - First cell

                $this->addOutput('<tr class="hiddenStatsTable">');
                
				$this->addOutput('<td class="hiddenStatsTableRow2">');

				//Takeoff
                $this->addOutput('<span>' . $this->L("takeoff_long") . '</span> :');

                if (isset($stat["TakeOffs"]) and is_array($stat["TakeOffs"]))
				{
                    foreach ($stat["TakeOffs"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["TakeOffs"]) or $stat["TakeOffs"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Landings

				$this->addOutput('<span>' . $this->L("landing_long") . ' :</span>');

				if (isset($stat["Lands"]) and is_array($stat["Lands"]))
				{
                    foreach ($stat["Lands"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["Lands"]) or $stat["Lands"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Fired Weapons

                $this->addOutput('<span>' . $this->L("firedArmement_long") . ' :</span>');

                if (isset($stat["Fired"]) and is_array($stat["Fired"]))
				{
                    foreach ($stat["Fired"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["Fired"]) or $stat["Fired"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                $this->addOutput('</td>');

				// SECOND ROW - Second cell

				$this->addOutput('<td class="hiddenStatsTableRow2">');

				// Friendly Fire

                $this->addOutput('<span>' . $this->L("teamKill") . ' :</span>');

				if (isset($stat["Killed"]["Destroyed"]) and is_array($stat["FriendlyFire"]))
				{
                    foreach ($stat["FriendlyFire"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["FriendlyFire"]) or $stat["FriendlyFire"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Hit by

                $this->addOutput('<span>' . $this->L("hitBy") . ' :</span>');

                if (isset($stat["Hit"]) and is_array($stat["Hit"]))
				{
                    foreach ($stat["Hit"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["Hit"]) or $stat["Hit"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Destroyed

				$this->addOutput('<span>' . $this->L("destroyed") . ' :</span>'); // ADDED Destroyed in pilot stats by Aikanaro

				if (isset($stat["Destroyed"]) and is_array($stat["Destroyed"]))
				{
                    foreach ($stat["Destroyed"] as $v)
					{
                        if ($v != "Count")
						{
                            $this->addOutput('<p>(' . $v . ')</p>'); // Fix bug count display destroyed in pilot stats by Aikanaro
						}
                    }
                }

                if (!isset($stat["Destroyed"]) or $stat["Destroyed"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                $this->addOutput('</td>');

				// SECOND ROW - Third Cell

				$this->addOutput('<td class="hiddenStatsTableRow2">');

				// Kill A/A

                $this->addOutput('<span>' . $this->L("killedAircraft") . ' :</span>');

				if (isset($stat["Killed"]["Aircraft"]) and is_array($stat["Killed"]["Aircraft"]))
				{
                    foreach ($stat["Killed"]["Aircraft"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["Killed"]["Aircraft"]) or $stat["Killed"]["Aircraft"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')<p/>');
				}

                // Kill Helo

                $this->addOutput('<span>' . $this->L("killedHelo") . ' :</span>');

                if (isset($stat["Killed"]["Helicopter"]) and is_array($stat["Killed"]["Helicopter"]))
				{
                    foreach ($stat["Killed"]["Helicopter"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["Killed"]["Helicopter"]) or $stat["Killed"]["Helicopter"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Kill Ship

                $this->addOutput('<span>' . $this->L("killedShip") . ' :</span>');

                if (isset($stat["Killed"]["Ship"]) and is_array($stat["Killed"]["Ship"]))
				{
                    foreach ($stat["Killed"]["Ship"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["Killed"]["Ship"]) or $stat["Killed"]["Ship"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Kill SAM/AAA

                $this->addOutput('<span>' . $this->L("killedSAM") . ' :</span>');

                if (isset($stat["Killed"]["SAM/AAA"]) and is_array($stat["Killed"]["SAM/AAA"]))
				{
                    foreach ($stat["Killed"]["SAM/AAA"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if (!isset($stat["Killed"]["SAM/AAA"]) or $stat["Killed"]["SAM/AAA"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Kill Tank

                $this->addOutput('<span>' . $this->L("killedTank") . ' :</span>');

                if (isset($stat["Killed"]["Tank"]) and is_array($stat["Killed"]["Tank"]))
				{
                    foreach ($stat["Killed"]["Tank"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if 	(!isset($stat["Killed"]["Tank"]) or $stat["Killed"]["Tank"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Kill Car

                $this->addOutput('<span>' . $this->L("killedCar") . ' :</span>');

                if (isset($stat["Killed"]["Car"]) and is_array($stat["Killed"]["Car"]))
				{
                    foreach ($stat["Killed"]["Car"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if 	(!isset($stat["Killed"]["Tank"]) or $stat["Killed"]["Tank"]["Count"] == "")
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                // Kill Car

                $this->addOutput('<span>' . $this->L("killedCar") . ' :</span>');

                if (isset($stat["Killed"]["Car"]) and is_array($stat["Killed"]["Car"]))
				{
                    foreach ($stat["Killed"]["Car"] as $k => $v)
					{
                        if ($k != "Count")
						{
                            $this->addOutput('<p>&nbsp;' . $k . ' (' . $v . ')</p>');
						}
                    }
                }

                if 	( !isset($stat["Killed"]["Car"]) or $stat["Killed"]["Car"]["Count"] == "") 
				{
                    $this->addOutput('<p>(' . $this->L("nothing") . ')</p>');
				}

                $this->addOutput('</td>');

                /*if (isset($stat["Hit"]) and $stat["Hit"]["Count"] != "")
				{
                    $this->addOutput('<td>');
                    $this->addOutput('</td>');
                }*/

                $this->addOutput('</tr>');

				//THIRD ROW - Events per pilot table

                $this->addOutput('<tr class="hiddenStatsTable">');

                $this->addOutput('<td class="hiddenStatsTable" colspan="3">');
                $this->addOutput('<h2>' . $this->L("events") . '</h2>');

                $this->addOutput('<table class="hiddenEventsTable">');
                $this->addOutput('<tr>');
                $this->addOutput('<th>' . $this->L('time') . '</th>');
                $this->addOutput('<th>' . $this->L('type') . '</th>');
                $this->addOutput('<th>' . $this->L('action') . '</th>');
                $this->addOutput('</tr>');

                foreach ($stat["Events"] as $key => $event)
				{
                    $this->displayEventRow($event);
                }

                $this->addOutput('</table>');

                $this->addOutput('</td>');
                $this->addOutput('</tr>');

                $this->addOutput('</table>');

                $this->addOutput('</td>');
                $this->addOutput('</tr>');

            }
        }

        $this->addOutput('</table>');

        // ***********************************************************
		// EVENTS TABLE - Display all events
		// ***********************************************************

		$this->addOutput('<h1>' . $this->L('events') . '</h1>');
        $this->addOutput('<table class="eventsTable">');
        $this->addOutput('<tr>');
        $this->addOutput('<th>' . $this->L('time') . '</th>');
        $this->addOutput('<th>' . $this->L('type') . '</th>');
        $this->addOutput('<th>' . $this->L('action') . '</th>');
        $this->addOutput('</tr>');

        foreach ($this->events as $key => $event)
		{
			$this->displayEventRow($event);
        }

        $this->addOutput('</table>');
	}

    // Add to output informations of one event

    function displayEventRow($event)
    {
        // hit ? des ?
        $hit = false;

        if ($event["Action"] == "HasBeenHitBy" or $event["Action"] == "HasBeenDestroyed")
		{
            $hit = true;
        }

        $this->addOutput('<tr>');

        // Time
        $this->addOutput('<td>');
        $this->addOutput($this->displayTime($this->startTime + $event["Time"]));
        $this->addOutput('</td>');

        // Type
        $this->addOutput('<td class="ptv_rowType">');

        switch ($event["PrimaryObject"]["Type"])
		{
            case "SAM/AAA":

                $lImage = '<img src="' . $this->image_path . 'categoryIcons/SAM-AAA_' . $event["PrimaryObject"]["Coalition"] . '.gif" alt="" />';

                break;

            case "Parachutist":

                $lImage = '<img src="' . $this->image_path . 'categoryIcons/Parachutist_.gif" alt="" />'; // ADDED icon Parachutis by Aikanaro

                break;

            case "Bomb":

                $lImage = '<img src="' . $this->image_path . 'categoryIcons/Bomb_' . $event["PrimaryObject"]["Coalition"] . '.gif" alt="" />'; // ADDED icon Bomb by Aikanaro

                break;

            case "Chaff":

                $lImage = '<img src="' . $this->image_path . 'categoryIcons/Chaff_' . $event["PrimaryObject"]["Coalition"] . '.gif" alt="" />'; // Added icon Chaff by Aikanaro

                break;

            case "Flare":

                $lImage = '<img src="' . $this->image_path . 'categoryIcons/Flare_' . $event["PrimaryObject"]["Coalition"] . '.gif" alt="" />'; // Added icon Flare by Aikanaro

                break;

            default:

                $lImage = '<img src="' . $this->image_path . 'categoryIcons/' . $event["PrimaryObject"]["Type"] . '_' . $event["PrimaryObject"]["Coalition"] . '.gif" alt="" />';

                break;
        }

		if ($hit === true and $event["Action"] == "HasBeenHitBy")
		{
            $lImage = '<img src="' . $this->image_path . 'categoryIcons/hit.gif" alt="" />';
        }

        $this->addOutput($lImage);
        $this->addOutput('</td>');

        // Name

		$class = "";

        if ($hit === true)
		{
			$class = $event["Action"] == "HasBeenHitBy" ? 'rowHit' : 'rowDestroy';

            if (	array_key_exists("SecondaryObject", $event) and 
					$event["PrimaryObject"]["Coalition"] == $event["SecondaryObject"]["Coalition"])
			{
                $class = "rowTeamKill";
            }
        }

		if ($class != "rowDestroy" && $class != "rowTeamKill")
		{
            // echo "clas to coalition:".var_dump($event["PrimaryObject"]);
            if (isset($event["PrimaryObject"]["Coalition"]))
			{
                $class = 'row' . $event["PrimaryObject"]["Coalition"];
			}
            else
			{
                $class = "other";
			}
        }
        $this->addOutput('<td class="ptv_' . $class . '">');

		$lmsg = "";

		$nameExists = array_key_exists("Name", $event["PrimaryObject"]);
		$pilotExists = array_key_exists("Pilot", $event["PrimaryObject"]) and $event["PrimaryObject"]["Pilot"] != "";
		$groupExists = array_key_exists("Group", $event["PrimaryObject"]) and $event["PrimaryObject"]["Group"] != "";

        if($class == "rowTeamKill")
		{
			$lmsg = $lmsg . '<span>*' . $this->L('teamKill') . '*</span> ';
		}

        if ($nameExists)
		{
            $lmsg = $lmsg . " " . $event["PrimaryObject"]["Name"] . " ";
        }

        if ($pilotExists)
		{

			$lmsg = $lmsg . "(" . $event["PrimaryObject"]["Pilot"] . ")";
		}

		if($groupExists)
		{

			$lmsg = $lmsg . " [" . $event["PrimaryObject"]["Group"] . "] ";	// ADDED Group in Event by Aikanaro
		}

        $this->addOutput($lmsg . $this->L($event["Action"]) . " ");

        // Action
        switch ($event["Action"])
		{

			case "HasLanded":
			case "HasTakeOff":	// obsolete
			case "HasTakenOff":

				if (isset($event["Airport"]) and $event["Airport"] != "")
				{
                    $this->addOutput(' <img src="' . $this->image_path . 'categoryIcons/airport.gif" alt="" /> ' . $event["Airport"]["Name"]);
                }
				else if(	array_key_exists("SecondaryObject", $event) and
							array_key_exists("Type", $event["SecondaryObject"]) and
							$event["SecondaryObject"]["Type"] == "Carrier")
				{
					$this->addOutput(' <img src="' . $this->image_path . 'categoryIcons/airport.gif" alt="" /> ' . $event["SecondaryObject"]["Name"]);

				}
				else
				{
                    $this->addOutput(' <img src="' . $this->image_path . 'categoryIcons/airport.gif" alt="" /> ');
                }

				break;

            case "HasBeenHitBy":

                // echo "hasbeebhit_>".$event["SecondaryObject"]["ID"];

				if(array_key_exists("SecondaryObject",$event))
				{
					$SecondaryObject = $event["SecondaryObject"];

					if(array_key_exists("Coalition",$SecondaryObject))
					{
						$SecondaryObjectCoalition = $SecondaryObject["Coalition"];

						$this->addOutput(' <img src="' . $this->image_path . 'categoryIcons/Mini_Missile_' . $SecondaryObjectCoalition . '.gif" alt="" /> ');

					}

					if (array_key_exists("Occurrences", $event))
					{
						$this->addOutput(' ' . $event["Occurrences"] . ' x ');
					}

					$this->addOutput($SecondaryObject["Name"]);

				}
				else	// No secondary object = no more info available
				{
					$this->addOutput('???');
				}

				if(array_key_exists("ParentObject",$event))
				{
					$ParentObject = $event["ParentObject"];

					if(array_key_exists("Pilot",$ParentObject))
					{
						$this->addOutput(' <i>[' . $ParentObject["Name"] . ' (' . $ParentObject["Pilot"] . ')</i>]');
					}
				}

				break;

            case "HasFired":

				if (array_key_exists("SecondaryObject",$event) && array_key_exists("Coalition", $event["SecondaryObject"]))
				{
					$this->addOutput(' <img src="' . $this->image_path . 'categoryIcons/Mini_Missile_' . $event["SecondaryObject"]["Coalition"] . '.gif" alt="" /> ');
				}
				if (array_key_exists("Occurrences", $event))
				{
					$this->addOutput(' ' . $event["Occurrences"] . ' x ');
				}

				$this->addOutput($event["SecondaryObject"]["Name"]);

                break;
        }

        $this->addOutput('</td>');
        $this->addOutput('</tr>');
    }


    // Aggiunto da 53.Sparrow per consentire l'utilizzo della funzione anche per le vecchie versioni di php
    function date_parse_from_format($format, $date)
    {
        $dt     = array(
            'hour' => '',
            'minute' => '',
            'second' => '',
            'year' => '',
            'month' => '',
            'day' => '',
            'other' => ''
        );
        // "YYYY?mm?dd?HH?ii?ss?"
        $dMask  = array(
            'H' => 'hour',
            'i' => 'minute',
            's' => 'second',
            'Y' => 'year',
            'm' => 'month',
            'd' => 'day',
            '?' => 'other'
        );
        $format = preg_split('//', $format, -1, PREG_SPLIT_NO_EMPTY);
        $date   = preg_split('//', $date, -1, PREG_SPLIT_NO_EMPTY);
        foreach ($date as $k => $v)
		{

            if ($dMask[$format[$k]])
			{
                $dt[$dMask[$format[$k]]] .= $v;
            }
        }

		return $dt;
    }

    //
    // Parse XML file and get events and objects
    //
    function parseXML($aFile)
    {
        $this->xmlParser = xml_parser_create();
        $this->xmlParser = xml_parser_create("UTF-8");

        xml_parser_set_option($this->xmlParser, XML_OPTION_CASE_FOLDING, false);
        xml_set_object($this->xmlParser, $this);
        xml_set_element_handler($this->xmlParser, "startTag", "endTag");
        xml_set_character_data_handler($this->xmlParser, "cdata");

        $lXmlData = file_get_contents($aFile);

        $data = xml_parse($this->xmlParser, $lXmlData);
        if (!$data)
		{
            die(sprintf("XML error: %s at line %d", xml_error_string(xml_get_error_code($this->xmlParser)), xml_get_current_line_number($this->xmlParser)));
        }

        xml_parser_free($this->xmlParser);
    }
    function startTag($aParser, $aName, $aAttrs)
    {
        $this->currentData = null;
        /*
         * // vettore generale Objects -- non esiste piu' --- if($aName == "Objects") { $this->tagObjectsOpened = true; } if($this->tagObjectsOpened === true) { if($aName == "Object") { $this->objectCurrentId = $aAttrs['ID']; $this->tagObjectOpened = true; } if($aName == "Parent") { if(array_key_exists('ID',$aAttrs)) { // Tacview 0.85 (obsolete) $this->objects[$this->objectCurrentId][$aName] = $this->objects[$aAttrs['ID']]; } } }
         */
        // vettore generale Events
        if ($aName == "Events")
		{
            $this->tagEventsOpened = true;
        }

        if ($this->tagEventsOpened === true)
		{

            if ($aName == "Event")
			{
                $lID                  = $this->eventCurrentId + 1;
                $this->eventCurrentId = $lID;
                $this->tagEventOpened = true;
            }

            if ($aName == "PrimaryObject")
			{
                $this->tagPrimaryObjectOpened = true;
            }

            if ($aName == "SecondaryObject")
			{
                $this->tagSecondaryObjectOpened = true;
            }

            if ($aName == "ParentObject")
			{
                $this->tagParentObjectOpened = true;
            }

            if ($aName == "Airport")
			{
                $this->tagAirportOpened = true;
            }

            if ($aName == "PrimaryObject")
			{
                if (array_key_exists('ID', $aAttrs))
				{
                    $this->events[$this->eventCurrentId][$aName]['ID'] = $aAttrs['ID'];
                }
            }

            if ($aName == "SecondaryObject")
			{
                if (array_key_exists('ID', $aAttrs))
				{
                    $this->events[$this->eventCurrentId][$aName]['ID'] = $aAttrs['ID'];
                }
            }

            if ($aName == "ParentObject")
			{
                if (array_key_exists('ID', $aAttrs))
				{
                    $this->events[$this->eventCurrentId][$aName]['ID'] = $aAttrs['ID'];
                }
            }
        }
    }

    function cdata($aParser, $aData)
    {

        if (trim($aData))
		{
            $this->currentData = $aData;
        }
    }

    function endTag($aParser, $aName)
    {
        if ($aName == "Title")
		{
            $this->missionName = $this->currentData;
        }

        if ($aName == "Duration")
		{
            $this->duration = $this->currentData;
        }

        if ($aName == "StartTime")
		{
            // Tacview 0.85 (obsolete)
            $this->startTime = $this->currentData;
        }

        if ($aName == "MissionTime")
		{
            // Tacview 0.93 (full UTC date format)
            $startTime       = $this->date_parse_from_format("YYYY?mm?dd?HH?ii?ss?", $this->currentData);
            $this->startTime = $startTime["hour"] * 60 * 60 + $startTime["minute"] * 60 + $startTime["second"];
        }

        /*
         * if($aName == "Objects") { $this->tagObjectsOpened = false; } if($this->tagObjectsOpened === true) { if($aName == "Object") { $this->tagObjectOpened = false; } if($aName == "Parent") { if($this->currentData) { $this->objects[$this->objectCurrentId][$aName] = $this->objects[$this->currentData]; } } if($aName != "Object" and $aName != "Parent") { $str = $this->currentData; if($aName == "Type") { if($str == "Bullet" or $str == "Shell") { $this->objects[$this->objectCurrentId]["Name"] = $this->L("Object".$str); } } $str = str_replace(' ', ' ', $str); $str = str_replace('Ã%u201A', ' ', $str); if(!isset($this->objects[$this->objectCurrentId][$aName])){ // Aggiunto da 53.Sparrow per consentire la visualizzazione dei proiettili $this->objects[$this->objectCurrentId][$aName] = $str; } } }
         */
        if ($aName == "Events")
		{
            $this->tagEventsOpened = false;
        }

        if ($this->tagEventsOpened === true)
		{

            if ($aName == "Event")
			{
                $this->tagEventOpened = false;
            }

            if ($aName == "PrimaryObject")
			{
                $this->tagPrimaryObjectOpened = false;
            }

            if ($aName == "SecondaryObject")
			{
                $this->tagSecondaryObjectOpened = false;
            }

            if ($aName == "ParentObject")
			{
                $this->tagParentObjectOpened = false;
            }

            if ($aName == "Airport")
			{
                $this->tagAirportOpened = false;
            }

            if ($aName != "Event" and $aName != "PrimaryObject" and $aName != "SecondaryObject" and $aName != "ParentObject" and $aName != "Airport")
			{
                if ($this->tagPrimaryObjectOpened === true)
				{
                    $this->events[$this->eventCurrentId]["PrimaryObject"][$aName] = $this->currentData;
				}
                else if ($this->tagSecondaryObjectOpened === true)
				{
                    $this->events[$this->eventCurrentId]["SecondaryObject"][$aName] = $this->currentData;
				}
                else if ($this->tagParentObjectOpened === true)
				{
                    $this->events[$this->eventCurrentId]["ParentObject"][$aName] = $this->currentData;
				}
                else if ($this->tagAirportOpened === true)
				{
                    $this->events[$this->eventCurrentId]["Airport"][$aName] = $this->currentData;
				}
                else
				{
                    $this->events[$this->eventCurrentId][$aName] = $this->currentData;
				}
            }

            /*
             * if($aName == "PrimaryObject" OR $aName == "SecondaryObject") { if($this->currentData) { //$this->events[$this->eventCurrentId][$aName] = $this->objects[$this->currentData]; $this->events[$this->eventCurrentId][$aName] = $this->currentData; } } if($aName != "Event" and $aName != "PrimaryObject" and $aName != "SecondaryObject") { $this->events[$this->eventCurrentId][$aName] = $this->currentData; }
             */
        }
    }
}

?>
