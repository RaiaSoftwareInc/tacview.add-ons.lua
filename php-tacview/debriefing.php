<!DOCTYPE html>
<html>
	<head>
		<title>PHPTacview</title>
		<link rel="stylesheet" href="tacview.css" />
		<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	</head>
	<body>
		<?php

			require_once "./tacview.php";

			$tv = new tacview("en");

			foreach (glob("debriefings/*.xml") as $filexml) {

				$tv->proceedStats("$filexml","Mission Test");

				echo $tv->getOutput();
			}

		?>
	</body>
</html>